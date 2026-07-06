with Ada.Containers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.History;
with Editor.Executor.Shared_Services;
with Editor.Feature_Search_Results;
with Editor.Files;
with Editor.Focus_Management;
with Editor.Navigation;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Render_Cache;

package body Editor.Executor.Semantic_Rename_Commands is

   use type Ada.Containers.Count_Type;
   use type Editor.Ada_Language_Service.Service_Status;
   use type Editor.Files.File_Open_Status;
   use type Editor.Files.File_Save_Status;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

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

   function Execute_Semantic_Rename_Command
     (S         : in out Editor.State.State_Type;
      Id        : Editor.Commands.Command_Id;
      Name      : String;
      Rename_To : String)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      case Id is
         when Editor.Commands.Command_Rename_Symbol_Preview =>
            declare
               Result : constant Editor.Ada_Language_Service.Rename_Preview :=
                 Semantic_Rename_Preview
                   (S, S.Language_Service, Name, Rename_To);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success
                 or else Result.Status = Editor.Ada_Language_Service.Service_Ambiguous
               then
                  Editor.Feature_Search_Results.Begin_External_Result_Set
                    (S.Feature_Search_Results,
                     Query        => "rename: " & Name & " -> " & Rename_To,
                     Source_Label => "Ada semantic rename preview");

                  for Target of Result.Edits loop
                     declare
                        Path   : constant String :=
                          To_String (Target.Target.Path);
                        Line   : constant Natural := Target.Target.Line;
                        Column : constant Natural := Target.Target.Column;
                        Label  : constant String :=
                          "edit " & Name & " -> " & Rename_To & " at " &
                          Path & ":" &
                          Ada.Strings.Fixed.Trim
                            (Natural'Image (Line), Ada.Strings.Both) &
                          ":" &
                          Ada.Strings.Fixed.Trim
                            (Natural'Image (Column), Ada.Strings.Both);
                     begin
                        Editor.Feature_Search_Results.Add_Search_Result
                          (S.Feature_Search_Results,
                           Label         => Label,
                           Source_Label  => Path,
                           Has_Target    => Target.Key.Buffer_Token /= 0,
                           Target_Buffer => Target.Key.Buffer_Token,
                           Target_Line   => Line,
                           Target_Column => Column,
                           Query         => Name,
                           Match_Line    => Line,
                           Match_Column  => Column,
                           Match_Length  => Name'Length);
                     end;
                  end loop;

                  for Target of Result.Conflicts loop
                     declare
                        Path   : constant String :=
                          To_String (Target.Target.Path);
                        Line   : constant Natural := Target.Target.Line;
                        Column : constant Natural := Target.Target.Column;
                        Conflict_Name : constant String :=
                          To_String (Target.Name);
                        Label  : constant String :=
                          "conflict " & Conflict_Name & " at " & Path & ":" &
                          Ada.Strings.Fixed.Trim
                            (Natural'Image (Line), Ada.Strings.Both) &
                          ":" &
                          Ada.Strings.Fixed.Trim
                            (Natural'Image (Column), Ada.Strings.Both);
                     begin
                        Editor.Feature_Search_Results.Add_Search_Result
                          (S.Feature_Search_Results,
                           Label         => Label,
                           Source_Label  => Path,
                           Has_Target    => Target.Key.Buffer_Token /= 0,
                           Target_Buffer => Target.Key.Buffer_Token,
                           Target_Line   => Line,
                           Target_Column => Column,
                           Query         => Conflict_Name,
                           Match_Line    => Line,
                           Match_Column  => Column,
                           Match_Length  => Conflict_Name'Length);
                     end;
                  end loop;

                  Editor.Feature_Search_Results
                    .Reconcile_Search_Results_After_Row_Change
                    (S.Feature_Search_Results, S.Feature_Panel,
                     Select_First_When_Available => True);
                  Editor.Panels.Set_Bottom_Content
                    (S.Panels, Editor.Panels.Search_Results_Content);
                  Editor.Panels.Set_Visible
                    (S.Panels, Editor.Panels.Bottom_Panel, True);
                  if Editor.Panel_Focus.Bottom_Panel_Has_Focus
                    (S.Panel_Focus)
                  then
                     Editor.Focus_Management.Set_Focus_Owner
                       (S,
                        Editor.Focus_Management.Focus_Project_Search_Results);
                  end if;
                  Editor.Panels.Set_Current (S.Panels);
                  Report_Info
                    (S,
                     "Rename preview for " & Name & ":" &
                     Natural'Image (Result.Edit_Count) & " edits," &
                     Natural'Image (Result.Conflict_Count) & " conflicts.");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info
                 (S, "Rename preview unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when Editor.Commands.Command_Rename_Symbol_Apply =>
            declare
               Result : constant Editor.Ada_Language_Service.Rename_Preview :=
                 Semantic_Rename_Preview
                   (S, S.Language_Service, Name, Rename_To);
               Reason : Unbounded_String;
               Applied_Count : Natural := 0;
               Processed :
                 Editor.Ada_Language_Service.Language_Target_Vectors.Vector;

               function Same_Apply_Target
                 (Left, Right : Editor.Ada_Language_Service.Language_Target)
                  return Boolean
               is
               begin
                  if Left.Key.Buffer_Token /= 0
                    and then Right.Key.Buffer_Token /= 0
                  then
                     return Left.Key.Buffer_Token = Right.Key.Buffer_Token;
                  end if;

                  return To_String (Left.Target.Path) =
                    To_String (Right.Target.Path);
               end Same_Apply_Target;
            begin
               Editor.Buffers.Ensure_Global_Registry (S);

               if not Rename_Preview_Is_Open_Buffers_Applyable
                 (S, Result, Reason)
               then
                  Report_Info (S, To_String (Reason));
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Unavailable (Id);
               end if;

               for Target of Result.Edits loop
                  declare
                     Already_Processed : Boolean := False;
                  begin
                     for Seen of Processed loop
                        if Same_Apply_Target (Seen, Target) then
                           Already_Processed := True;
                           exit;
                        end if;
                     end loop;

                     if not Already_Processed then
                        declare
                           Found_Open : Boolean := False;
                           Buffer_Id  : Editor.Buffers.Buffer_Id :=
                             Editor.Buffers.No_Buffer;
                           Buffer_State : Editor.State.State_Type;
                           Open_Result : Editor.Files.File_Open_Result;
                           Cmd : Editor.Commands.Command;
                           Before_Text : Unbounded_String;
                           Replaced : Boolean := False;
                        begin
                           if Target.Key.Buffer_Token = S.Active_Buffer_Token
                           then
                              Buffer_Id := Editor.Buffers.Buffer_Id
                                (S.Active_Buffer_Token);
                              Found_Open := True;
                              Buffer_State := S;
                           elsif Target.Key.Buffer_Token /= 0
                             and then Editor.Buffers.Global_Contains
                               (Editor.Buffers.Buffer_Id
                                  (Target.Key.Buffer_Token))
                           then
                              Buffer_Id := Editor.Buffers.Buffer_Id
                                (Target.Key.Buffer_Token);
                              Found_Open := True;
                              Buffer_State :=
                                Editor.Buffers.Global_Buffer (Buffer_Id);
                           else
                              Buffer_Id := Editor.Buffers.Global_Find_By_Path
                                (To_String (Target.Target.Path), Found_Open);
                              if Found_Open then
                                 Buffer_State :=
                                   Editor.Buffers.Global_Buffer (Buffer_Id);
                              else
                                 Open_Result := Editor.Files.Open_File
                                   (To_String (Target.Target.Path));
                                 Editor.State.Initialize (Buffer_State);
                                 Editor.State.Replace_Buffer_Contents
                                   (Buffer_State,
                                    To_String (Open_Result.Contents));
                                 Buffer_State.File_Info.Has_Path := True;
                                 Buffer_State.File_Info.Path :=
                                   Open_Result.Path;
                                 Buffer_State.File_Info.Display_Name :=
                                   Open_Result.Display_Name;
                              end if;
                           end if;

                           Before_Text := To_Unbounded_String
                             (Editor.State.Current_Text (Buffer_State));
                           Cmd.Kind := Editor.Commands.Apply_Replace_Batch;

                           for Edit of Result.Edits loop
                              if Same_Apply_Target (Edit, Target) then
                                 declare
                                    Pos : constant Natural :=
                                      Editor.Navigation.Index_For_Line_Column
                                        (Buffer_State,
                                         Edit.Target.Line - 1,
                                         Edit.Target.Column - 1);
                                    Current : constant String :=
                                      To_String
                                        (Editor.Executor.Extract_Text
                                           (Buffer_State.Buffer, Pos,
                                            Name'Length));
                                 begin
                                    if Current = Name then
                                       Editor.Executor.Append_Replace_Op
                                         (Cmd,
                                          Editor.Cursors.Cursor_Index (Pos),
                                          Name'Length,
                                          To_Unbounded_String (Rename_To));
                                    end if;
                                 end;
                              end if;
                           end loop;

                           if Cmd.Positions.Length > 0 then
                              Editor.Executor.History
                                .Apply_Replace_Batch_Command
                                (Buffer_State, Cmd);
                              if Editor.State.Current_Text (Buffer_State) /=
                                Before_Text
                              then
                                 if Found_Open then
                                    Editor.Buffers
                                      .Global_Replace_Buffer_Contents
                                      (Buffer_Id,
                                       Editor.State.Current_Text
                                         (Buffer_State),
                                       Replaced);
                                 else
                                    Replaced :=
                                      Editor.Files.Save_File
                                        (To_String (Target.Target.Path),
                                         Editor.State.Current_Text
                                           (Buffer_State)).Status =
                                      Editor.Files.File_Save_Ok;
                                 end if;

                                 if Replaced then
                                    if Found_Open then
                                       Editor.Ada_Project_Index
                                         .Invalidate_Buffer
                                         (S.Language_Index,
                                          Natural (Buffer_Id));
                                       Editor.Ada_Language_Service
                                         .Invalidate_Buffer
                                         (S.Language_Service,
                                          Natural (Buffer_Id));
                                    else
                                       Editor.Ada_Project_Index
                                         .Invalidate_Path
                                         (S.Language_Index,
                                          To_String (Target.Target.Path));
                                       Editor.Ada_Language_Service
                                         .Invalidate_Path
                                         (S.Language_Service,
                                          To_String (Target.Target.Path));
                                    end if;

                                    Applied_Count :=
                                      Applied_Count +
                                      Natural (Cmd.Positions.Length);
                                 end if;
                              end if;
                           end if;
                        end;

                        Processed.Append (Target);
                     end if;
                  end;
               end loop;

               if Applied_Count = 0 then
                  Report_Info
                    (S, "Rename apply for " & Name & ": no edits.");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.No_Op (Id);
               end if;

               Editor.Buffers.Load_Global_Active_Into_State (S);

               Report_Info
                 (S,
                  "Rename applied for " & Name & ":" &
                  Natural'Image (Applied_Count) & " edits.");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Executed (Id);
            end;

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Semantic_Rename_Command;

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
