with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Command_Execution;
with Editor.Executor;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Semantic_Outline_Targets;
with Editor.Executor.Semantic_Service_Commands;
with Editor.Executor.Shared_Services;
with Editor.Feature_Panel;
with Editor.Navigation;
with Editor.Outline;
with Editor.Recent_Projects;
with Editor.Render_Cache;

package body Editor.Executor.Semantic_Navigation_Commands is

   use type Editor.Ada_Language_Model.Symbol_Kind;
   use type Editor.Ada_Language_Service.Service_Status;
   use type Editor.Commands.Command_Id;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   function Active_Feature_Buffer_Token
     (S : Editor.State.State_Type) return Natural
      renames Editor.Executor.Active_Feature_Buffer_Token;

   function Service_Status_Image
     (Status : Editor.Ada_Language_Service.Service_Status) return String
   is
   begin
      case Status is
         when Editor.Ada_Language_Service.Service_Success =>
            return "success";
         when Editor.Ada_Language_Service.Service_Unavailable =>
            return "unavailable";
         when Editor.Ada_Language_Service.Service_Ambiguous =>
            return "ambiguous";
         when Editor.Ada_Language_Service.Service_Overflow =>
            return "overflow";
         when Editor.Ada_Language_Service.Service_Stale =>
            return "stale";
      end case;
   end Service_Status_Image;

   function Current_Language_Service
     (S : Editor.State.State_Type)
      return Editor.Ada_Language_Service.Service_State
   is
      Service_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Service);
      Index_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Index);
   begin
      if Service_Status.File_Count = Index_Status.File_Count
        and then Service_Status.Unit_Count = Index_Status.Unit_Count
        and then Service_Status.Symbol_Count = Index_Status.Symbol_Count
        and then Service_Status.Fingerprint = Index_Status.Fingerprint
        and then Service_Status.Overflowed = Index_Status.Overflowed
      then
         return S.Language_Service;
      end if;

      return Editor.Ada_Language_Service.From_Index (S.Language_Index);
   end Current_Language_Service;

   procedure Ensure_Current_Language_Service
     (S : in out Editor.State.State_Type)
   is
      Service_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Service);
      Index_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Index);
   begin
      if Service_Status.File_Count /= Index_Status.File_Count
        or else Service_Status.Unit_Count /= Index_Status.Unit_Count
        or else Service_Status.Symbol_Count /= Index_Status.Symbol_Count
        or else Service_Status.Fingerprint /= Index_Status.Fingerprint
        or else Service_Status.Overflowed /= Index_Status.Overflowed
      then
         Editor.Ada_Language_Service.Put_Index
           (S.Language_Service, S.Language_Index);
      end if;
   end Ensure_Current_Language_Service;

   function Current_Semantic_Analysis_Fingerprint
     (S    : Editor.State.State_Type;
      Path : String) return Natural
   is
      Indexed_Fingerprint : constant Natural :=
        Editor.Ada_Project_Index.Current_Analysis_Fingerprint
          (S.Language_Index,
           Path,
           S.Active_Buffer_Token,
           Editor.State.Current_Buffer_Revision (S),
           Editor.State.Current_Lifecycle_Generation (S));
   begin
      if Indexed_Fingerprint /= 0 then
         return Indexed_Fingerprint;
      end if;

      return Editor.Ada_Language_Model.Fingerprint (S.Syntax_Analysis);
   end Current_Semantic_Analysis_Fingerprint;

   function Semantic_Declaration_Target
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Symbol  : Semantic_Symbol)
      return Editor.Ada_Language_Service.Language_Target
   is
      Name         : constant String := To_String (Symbol.Name);
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Target       : Editor.Ada_Language_Service.Language_Target;
      Req          : Editor.Ada_Language_Service.Semantic_Request_Id;
   begin
      if Current_File.Has_Path
        and then S.Active_Buffer_Token /= 0
      then
         declare
            Current_Path : constant String := To_String (Current_File.Path);
            Fingerprint  : constant Natural :=
              Current_Semantic_Analysis_Fingerprint (S, Current_Path);
         begin
            Req := Editor.Ada_Language_Service.Begin_Semantic_Request
              (Service,
               Editor.Ada_Language_Service.Semantic_Request_Goto_Declaration,
               Editor.Ada_Language_Service.Semantic_Current_Request_Query_Key
                 (Editor.Ada_Language_Service.Semantic_Request_Goto_Declaration,
                  Name, Current_Path,
                  S.Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Fingerprint,
                  Detail => Editor.Ada_Language_Model.Symbol_Kind'Image
                    (Symbol.Kind)));
            Target :=
              Editor.Ada_Language_Service.Request_Goto_Declaration_Current
                (Service, Req, Name, Symbol.Kind, Current_Path,
                 S.Active_Buffer_Token,
                 Editor.State.Current_Buffer_Revision (S),
                 Editor.State.Current_Lifecycle_Generation (S),
                 Fingerprint);
         end;
      else
         Req := Editor.Ada_Language_Service.Begin_Semantic_Request
           (Service,
            Editor.Ada_Language_Service.Semantic_Request_Goto_Declaration,
            Editor.Ada_Language_Service.Semantic_Request_Query_Key
              (Editor.Ada_Language_Service.Semantic_Request_Goto_Declaration,
               Name,
               Detail => Editor.Ada_Language_Model.Symbol_Kind'Image
                 (Symbol.Kind)));
         Target := Editor.Ada_Language_Service.Request_Goto_Declaration
           (Service, Req, Name, Symbol.Kind);
      end if;

      if Target.Status = Editor.Ada_Language_Service.Service_Success
        or else Symbol.Kind /= Editor.Ada_Language_Model.Symbol_Unknown
      then
         return Target;
      end if;

      declare
         Hover : constant Editor.Ada_Language_Service.Hover_Result :=
           Editor.Executor.Semantic_Service_Commands.Semantic_Hover
             (S, Service, Name);
      begin
         if Hover.Status = Editor.Ada_Language_Service.Service_Success then
            return
              (Status => Hover.Status,
               Target => Hover.Target,
               Key    => Hover.Key,
               Name   => Hover.Label,
               Detail => Hover.Detail);
         end if;

         Target.Status := Hover.Status;
      end;

      return Target;
   end Semantic_Declaration_Target;

   function Has_Indexed_Outline_Target
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return Boolean
   is
      Service : Editor.Ada_Language_Service.Service_State :=
        Current_Language_Service (S);
   begin
      return Editor.Executor.Semantic_Outline_Targets
        .Find_Indexed_Outline_Target (S, Id, Service).Available;
   end Has_Indexed_Outline_Target;

   function Navigate_To_Indexed_Outline_Target
     (S      : in out Editor.State.State_Type;
      Target : Editor.Executor.Semantic_Outline_Targets
        .Outline_Indexed_Target) return Boolean
   is
      Path : constant String := To_String (Target.Path);

      function Same_Target_Path (Left : String; Right : String) return Boolean is
      begin
         return Editor.Recent_Projects.Normalized_Root_Path (Left) =
           Editor.Recent_Projects.Normalized_Root_Path (Right);
      end Same_Target_Path;
   begin
      if not Target.Available or else Path'Length = 0 then
         return False;
      end if;

      if not Editor.Ada_Project_Index.Contains_Key
        (S.Language_Index, Target.Key)
      then
         return False;
      end if;

      if not S.File_Info.Has_Path
        or else not Same_Target_Path (To_String (S.File_Info.Path), Path)
      then
         declare
            Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
              S.Language_Index;
            Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
              S.Language_Service;
         begin
            Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
            S.Language_Index := Saved_Index;
            S.Language_Service := Saved_Service;
         end;
      end if;

      if not S.File_Info.Has_Path
        or else not Same_Target_Path (To_String (S.File_Info.Path), Path)
      then
         return False;
      end if;

      if Target.Key.Buffer_Token /= 0
        and then not Editor.Ada_Project_Index.Contains_Open_Buffer_Key
          (S.Language_Index,
           Target.Key,
           Path,
           Active_Feature_Buffer_Token (S),
           Editor.State.Current_Buffer_Revision (S),
           Editor.State.Current_Lifecycle_Generation (S))
      then
         return False;
      end if;

      if Natural (Target.Line) > Editor.State.Line_Count (S)
        or else Natural (Target.Column) - 1 >
          Editor.Navigation.Line_Length (S, Natural (Target.Line) - 1)
      then
         return False;
      end if;

      Editor.Executor.Apply_Feature_Target_Handoff
        (S,
         Natural (Target.Line) - 1,
         Natural (Target.Column) - 1);
      return True;
   end Navigate_To_Indexed_Outline_Target;

   function Semantic_Navigation_Command_Availability
     (S      : Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Symbol : Semantic_Symbol)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Goto_Declaration =>
            if Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
              and then Editor.Executor.Has_Selected_Outline_Activation_Target
                (S)
            then
               return Editor.Commands.Available;
            else
               declare
                  Service : Editor.Ada_Language_Service.Service_State :=
                    Current_Language_Service (S);
                  Target  : Editor.Ada_Language_Service.Language_Target;
               begin
                  if not Symbol.Available then
                     return Editor.Commands.Unavailable
                       ("No semantic symbol at cursor or Outline selection.");
                  end if;

                  Target := Semantic_Declaration_Target
                    (S, Service, Symbol);
                  if Target.Status =
                    Editor.Ada_Language_Service.Service_Success
                  then
                     return Editor.Commands.Available;
                  end if;

                  return Editor.Commands.Unavailable
                    ("Declaration unavailable for " &
                     To_String (Symbol.Name) & ": " &
                     Service_Status_Image (Target.Status) & ".");
               end;
            end if;

         when Editor.Commands.Command_Goto_Body
            | Editor.Commands.Command_Goto_Spec =>
            if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_Feature_Panel_Hidden);
            elsif not Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
              or else not Editor.Outline.Validate_Outline_Row_For_Selection
                (S.Outline,
                 S.Feature_Panel,
                 Editor.Feature_Panel.Selected_Row (S.Feature_Panel))
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Outline_Item_Selected);
            elsif not Has_Indexed_Outline_Target (S, Id) then
               return Editor.Commands.Unavailable
                 ("Outline indexed target unavailable");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Unsupported semantic navigation command.");
      end case;
   end Semantic_Navigation_Command_Availability;

   function Execute_Semantic_Navigation_Command
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Symbol : Semantic_Symbol)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      case Id is
         when Editor.Commands.Command_Goto_Declaration =>
            if Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
              and then Editor.Executor.Has_Selected_Outline_Activation_Target
                (S)
            then
               return Editor.Executor.Execute_Command_With_Result
                 (S, Editor.Commands.Command_Open_Selected_Outline_Item);
            else
               declare
                  Target : Editor.Ada_Language_Service.Language_Target;
               begin
                  Ensure_Current_Language_Service (S);
                  if not Symbol.Available then
                     Report_Info
                       (S, "No semantic symbol at cursor or Outline selection.");
                     Editor.Render_Cache.Invalidate_All;
                     return Editor.Command_Execution.Unavailable (Id);
                  end if;

                  Target := Semantic_Declaration_Target
                    (S, S.Language_Service, Symbol);
                  if Target.Status =
                    Editor.Ada_Language_Service.Service_Success
                    and then Navigate_To_Indexed_Outline_Target
                      (S,
                       (Available => True,
                        Path      => Target.Target.Path,
                        Key       => Target.Key,
                        Line      => Target.Target.Line,
                        Column    => Target.Target.Column))
                  then
                     Editor.Render_Cache.Invalidate_All;
                     return Editor.Command_Execution.Executed (Id);
                  end if;

                  Report_Info
                    (S,
                     "Declaration unavailable for " &
                     To_String (Symbol.Name) & ": " &
                     Service_Status_Image (Target.Status) & ".");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Unavailable (Id);
               end;
            end if;

         when Editor.Commands.Command_Goto_Body
            | Editor.Commands.Command_Goto_Spec =>
            declare
               Target : Editor.Executor.Semantic_Outline_Targets
                 .Outline_Indexed_Target;
            begin
               Ensure_Current_Language_Service (S);
               Target := Editor.Executor.Semantic_Outline_Targets
                 .Find_Indexed_Outline_Target
                   (S, Id, S.Language_Service, Track_Request => True);
               if Navigate_To_Indexed_Outline_Target (S, Target) then
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info (S, "Outline indexed target unavailable");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Semantic_Navigation_Command;

end Editor.Executor.Semantic_Navigation_Commands;
