with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;

package body Editor.Executor.Semantic_Service_Commands is

   use type Editor.Ada_Language_Service.Service_Status;

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

   function Semantic_Find_References
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Ada_Language_Service.Language_Target_Set
   is
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Req : Editor.Ada_Language_Service.Semantic_Request_Id;
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
               Editor.Ada_Language_Service.Semantic_Request_Find_References,
               Editor.Ada_Language_Service.Semantic_Current_Request_Query_Key
                 (Editor.Ada_Language_Service.Semantic_Request_Find_References,
                  Name, Current_Path,
                  S.Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Fingerprint));
            return Editor.Ada_Language_Service.Request_Find_Current_References
              (Service, Req, Name, Current_Path,
               S.Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Fingerprint);
         end;
      end if;

      Req := Editor.Ada_Language_Service.Begin_Semantic_Request
        (Service, Editor.Ada_Language_Service.Semantic_Request_Find_References,
         Name);
      return Editor.Ada_Language_Service.Request_Find_References
        (Service, Req, Name);
   end Semantic_Find_References;

   function Semantic_Workspace_Symbols
     (Service : in out Editor.Ada_Language_Service.Service_State;
      Query   : String)
      return Editor.Ada_Language_Service.Language_Target_Set
   is
      Req : constant Editor.Ada_Language_Service.Semantic_Request_Id :=
        Editor.Ada_Language_Service.Begin_Semantic_Request
          (Service,
           Editor.Ada_Language_Service.Semantic_Request_Workspace_Symbols,
           Query);
   begin
      return Editor.Ada_Language_Service.Request_Workspace_Symbols
        (Service, Req, Query);
   end Semantic_Workspace_Symbols;

   function Semantic_Hover
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Ada_Language_Service.Hover_Result
   is
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Req : Editor.Ada_Language_Service.Semantic_Request_Id;
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
              (Service, Editor.Ada_Language_Service.Semantic_Request_Hover,
               Editor.Ada_Language_Service.Semantic_Current_Request_Query_Key
                 (Editor.Ada_Language_Service.Semantic_Request_Hover,
                  Name, Current_Path,
                  S.Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Fingerprint));
            return Editor.Ada_Language_Service.Request_Hover_Current
              (Service, Req, Name, Current_Path,
               S.Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Fingerprint);
         end;
      end if;

      Req := Editor.Ada_Language_Service.Begin_Semantic_Request
        (Service, Editor.Ada_Language_Service.Semantic_Request_Hover, Name);
      return Editor.Ada_Language_Service.Request_Hover (Service, Req, Name);
   end Semantic_Hover;

   function Semantic_Complete
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Prefix  : String;
      Limit   : Positive)
      return Editor.Ada_Language_Service.Completion_Result
   is
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Req : Editor.Ada_Language_Service.Semantic_Request_Id;
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
              (Service, Editor.Ada_Language_Service.Semantic_Request_Completion,
               Editor.Ada_Language_Service.Semantic_Current_Request_Query_Key
                 (Editor.Ada_Language_Service.Semantic_Request_Completion,
                  Prefix, Current_Path,
                  S.Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Fingerprint,
                  Detail => Positive'Image (Limit)));
            return Editor.Ada_Language_Service.Request_Complete_Current
              (Service, Req, Prefix, Current_Path,
               S.Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Fingerprint,
               Limit);
         end;
      end if;

      Req := Editor.Ada_Language_Service.Begin_Semantic_Request
        (Service, Editor.Ada_Language_Service.Semantic_Request_Completion,
         Editor.Ada_Language_Service.Semantic_Request_Query_Key
           (Editor.Ada_Language_Service.Semantic_Request_Completion,
            Prefix, Detail => Positive'Image (Limit)));
      return Editor.Ada_Language_Service.Request_Complete
        (Service, Req, Prefix, Limit);
   end Semantic_Complete;

   function Semantic_Service_Command_Availability
     (S       : Editor.State.State_Type;
      Id      : Editor.Commands.Command_Id;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Find_References =>
            declare
               Result : constant Editor.Ada_Language_Service.Language_Target_Set :=
                 Semantic_Find_References (S, Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable
                 ("References unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
            end;

         when Editor.Commands.Command_Workspace_Symbols =>
            declare
               Result : constant Editor.Ada_Language_Service.Language_Target_Set :=
                 Semantic_Workspace_Symbols (Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable
                 ("Workspace symbols unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
            end;

         when Editor.Commands.Command_Show_Hover =>
            declare
               Result : constant Editor.Ada_Language_Service.Hover_Result :=
                 Semantic_Hover (S, Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable
                 ("Hover unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
            end;

         when Editor.Commands.Command_Show_Completions =>
            declare
               Result : constant Editor.Ada_Language_Service.Completion_Result :=
                 Semantic_Complete (S, Service, Name, 20);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable
                 ("Completions unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
            end;

         when others =>
            return Editor.Commands.Unavailable
              ("Unsupported semantic service command.");
      end case;
   end Semantic_Service_Command_Availability;

end Editor.Executor.Semantic_Service_Commands;
