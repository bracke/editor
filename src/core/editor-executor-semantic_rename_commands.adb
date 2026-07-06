with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;
with Editor.Buffers;
with Editor.Files;
with Editor.Navigation;

package body Editor.Executor.Semantic_Rename_Commands is

   use type Editor.Ada_Language_Service.Service_Status;
   use type Editor.Files.File_Open_Status;

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

   function Semantic_Rename_Preview
     (S        : Editor.State.State_Type;
      Service  : in out Editor.Ada_Language_Service.Service_State;
      Old_Name : String;
      New_Name : String)
      return Editor.Ada_Language_Service.Rename_Preview
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
              (Service, Editor.Ada_Language_Service.Semantic_Request_Rename,
               Editor.Ada_Language_Service.Semantic_Current_Request_Query_Key
                 (Editor.Ada_Language_Service.Semantic_Request_Rename,
                  Old_Name, Current_Path,
                  S.Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Fingerprint,
                  Detail => New_Name));
            return Editor.Ada_Language_Service.Request_Preview_Rename_Current
              (Service, Req, Old_Name, New_Name, Current_Path,
               S.Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Fingerprint);
         end;
      end if;

      Req := Editor.Ada_Language_Service.Begin_Semantic_Request
        (Service, Editor.Ada_Language_Service.Semantic_Request_Rename,
         Editor.Ada_Language_Service.Semantic_Request_Query_Key
           (Editor.Ada_Language_Service.Semantic_Request_Rename,
            Old_Name, Detail => New_Name));
      return Editor.Ada_Language_Service.Request_Preview_Rename
        (Service, Req, Old_Name, New_Name);
   end Semantic_Rename_Preview;

   function Rename_Preview_Is_Open_Buffers_Applyable
     (S       : Editor.State.State_Type;
      Preview : Editor.Ada_Language_Service.Rename_Preview;
      Reason  : out Unbounded_String) return Boolean
   is
      Old_Name : constant String := To_String (Preview.Old_Name);
      New_Name : constant String := To_String (Preview.New_Name);
      function Buffer_For_Target
        (Target : Editor.Ada_Language_Service.Language_Target)
         return Editor.State.State_Type
      is
         Found : Boolean := False;
         Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
         Open  : Editor.Files.File_Open_Result;
         Temp  : Editor.State.State_Type;
      begin
         if Target.Key.Buffer_Token = S.Active_Buffer_Token then
            return S;
         elsif Target.Key.Buffer_Token /= 0
           and then Editor.Buffers.Global_Contains
             (Editor.Buffers.Buffer_Id (Target.Key.Buffer_Token))
         then
            return Editor.Buffers.Global_Buffer
              (Editor.Buffers.Buffer_Id (Target.Key.Buffer_Token));
         end if;

         Id := Editor.Buffers.Global_Find_By_Path
           (To_String (Target.Target.Path), Found);
         if Found then
            return Editor.Buffers.Global_Buffer (Id);
         end if;

         Open := Editor.Files.Open_File (To_String (Target.Target.Path));
         if Open.Status = Editor.Files.File_Open_Ok then
            Editor.State.Initialize (Temp);
            Editor.State.Replace_Buffer_Contents
              (Temp, To_String (Open.Contents));
            Temp.File_Info.Has_Path := True;
            Temp.File_Info.Path := Open.Path;
            Temp.File_Info.Display_Name := Open.Display_Name;
            return Temp;
         end if;

         return S;
      end Buffer_For_Target;

      function Target_State_Available
        (Target : Editor.Ada_Language_Service.Language_Target) return Boolean
      is
         Found : Boolean := False;
      begin
         if Target.Key.Buffer_Token = S.Active_Buffer_Token then
            return True;
         elsif Target.Key.Buffer_Token /= 0
           and then Editor.Buffers.Global_Contains
             (Editor.Buffers.Buffer_Id (Target.Key.Buffer_Token))
         then
            return True;
         end if;

         declare
            Ignored : constant Editor.Buffers.Buffer_Id :=
              Editor.Buffers.Global_Find_By_Path
                (To_String (Target.Target.Path), Found);
            pragma Unreferenced (Ignored);
         begin
            if Found then
               return True;
            end if;
         end;

         return Editor.Files.Open_File (To_String (Target.Target.Path)).Status =
           Editor.Files.File_Open_Ok;
      end Target_State_Available;
   begin
      Reason := Null_Unbounded_String;

      if Preview.Status /= Editor.Ada_Language_Service.Service_Success then
         Reason := To_Unbounded_String
           ("Rename apply unavailable for " & Old_Name & ": " &
            Service_Status_Image (Preview.Status) & ".");
         return False;
      elsif Preview.Conflict_Count > 0 then
         Reason := To_Unbounded_String
           ("Rename apply blocked for " & Old_Name & ": conflicts.");
         return False;
      elsif Preview.Edit_Count = 0 then
         Reason := To_Unbounded_String
           ("Rename apply unavailable for " & Old_Name & ": no edits.");
         return False;
      elsif S.Active_Buffer_Token = 0 then
         Reason := To_Unbounded_String
           ("Rename apply unavailable for " & Old_Name & ": no active buffer.");
         return False;
      end if;

      for Target of Preview.Edits loop
         if not Target_State_Available (Target) then
            Reason := To_Unbounded_String
              ("Rename apply unavailable for " & Old_Name &
               ": target file unavailable.");
            return False;
         else
            declare
               Target_State : constant Editor.State.State_Type :=
                 Buffer_For_Target (Target);
               Found_Open_By_Path : Boolean := False;
               Open_By_Path_Id : constant Editor.Buffers.Buffer_Id :=
                 Editor.Buffers.Global_Find_By_Path
                   (To_String (Target.Target.Path), Found_Open_By_Path);
               pragma Unreferenced (Open_By_Path_Id);
               Open_Target : constant Boolean :=
                 Target.Key.Buffer_Token = S.Active_Buffer_Token
                 or else
                   (Target.Key.Buffer_Token /= 0
                    and then Editor.Buffers.Global_Contains
                      (Editor.Buffers.Buffer_Id (Target.Key.Buffer_Token)));
            begin
               if Open_Target
                 and then not Editor.Executor.Feature_Target_Position_Is_Valid
                   (Target_State, Target.Key.Buffer_Token,
                    Target.Target.Line, Target.Target.Column)
               then
                  Reason := To_Unbounded_String
                    ("Rename apply unavailable for " & Old_Name &
                     ": stale edit target.");
                  return False;
               elsif (not Open_Target)
                 and then
                   (Target.Target.Line = 0
                    or else Target.Target.Column = 0
                    or else Target.Target.Line >
                      Editor.State.Line_Count (Target_State)
                    or else Target.Target.Column - 1 >
                      Editor.Navigation.Line_Length
                        (Target_State, Target.Target.Line - 1))
               then
                  Reason := To_Unbounded_String
                    ("Rename apply unavailable for " & Old_Name &
                     ": stale edit target.");
                  return False;
               elsif Target.Target.Column = 0
                 or else Target.Target.Column - 1 + Old_Name'Length >
                   Editor.Navigation.Line_Length
                     (Target_State, Target.Target.Line - 1)
               then
                  Reason := To_Unbounded_String
                    ("Rename apply unavailable for " & Old_Name &
                     ": stale edit target.");
                  return False;
               else
                  declare
                     Pos : constant Natural :=
                       Editor.Navigation.Index_For_Line_Column
                         (Target_State, Target.Target.Line - 1,
                          Target.Target.Column - 1);
                     Current : constant String :=
                       To_String
                         (Editor.Executor.Extract_Text
                            (Target_State.Buffer, Pos, Old_Name'Length));
                  begin
                     if Current /= Old_Name and then Current /= New_Name then
                        Reason := To_Unbounded_String
                          ("Rename apply unavailable for " & Old_Name &
                           ": stale edit target.");
                        return False;
                     end if;
                  end;
               end if;
            end;
         end if;
      end loop;

      return True;
   end Rename_Preview_Is_Open_Buffers_Applyable;

   function Semantic_Rename_Command_Availability
     (S       : Editor.State.State_Type;
      Id      : Editor.Commands.Command_Id;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Commands.Command_Availability
   is
      Result : constant Editor.Ada_Language_Service.Rename_Preview :=
        Semantic_Rename_Preview (S, Service, Name, Name & "_Renamed");
   begin
      case Id is
         when Editor.Commands.Command_Rename_Symbol_Preview =>
            if Result.Status = Editor.Ada_Language_Service.Service_Success
              or else Result.Status = Editor.Ada_Language_Service.Service_Ambiguous
            then
               return Editor.Commands.Available;
            end if;
            return Editor.Commands.Unavailable
              ("Rename preview unavailable for " & Name & ": " &
               Service_Status_Image (Result.Status) & ".");

         when Editor.Commands.Command_Rename_Symbol_Apply =>
            declare
               Reason : Unbounded_String;
            begin
               if Rename_Preview_Is_Open_Buffers_Applyable
                 (S, Result, Reason)
               then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable (To_String (Reason));
            end;

         when others =>
            return Editor.Commands.Unavailable
              ("Unsupported semantic rename command.");
      end case;
   end Semantic_Rename_Command_Availability;

end Editor.Executor.Semantic_Rename_Commands;
