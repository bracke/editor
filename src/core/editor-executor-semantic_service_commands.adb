with Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings;
with Ada.Strings.Fixed;

with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;
with Editor.Command_Execution;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.Semantic_Service_State;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Feature_Search_Results;
with Editor.Focus_Management;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Render_Cache;

package body Editor.Executor.Semantic_Service_Commands is

   use type Editor.Ada_Language_Service.Service_Status;
   use type Ada.Containers.Count_Type;

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

   procedure Ensure_Current_Language_Service
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Service_State
        .Ensure_Current_Language_Service;

   function Execute_Semantic_Service_Command
     (S    : in out Editor.State.State_Type;
      Id   : Editor.Commands.Command_Id;
      Name : String)
      return Editor.Command_Execution.Command_Execution_Result
   is
      function Safe_Caret return Editor.Cursors.Cursor_Index is
      begin
         return Editor.Executor.Safe_Caret (S);
      end Safe_Caret;
   begin
      Ensure_Current_Language_Service (S);

      case Id is
         when Editor.Commands.Command_Find_References =>
            declare
               Result : constant Editor.Ada_Language_Service.Language_Target_Set :=
                 Semantic_Find_References (S, S.Language_Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  Editor.Feature_Search_Results.Begin_External_Result_Set
                    (S.Feature_Search_Results,
                     Query        => "references: " & Name,
                     Source_Label => "Ada semantic references");

                  for Target of Result.Targets loop
                     declare
                        Path   : constant String := To_String (Target.Target.Path);
                        Line   : constant Natural := Target.Target.Line;
                        Column : constant Natural := Target.Target.Column;
                        Label  : constant String :=
                          Name & " at " & Path & ":" &
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

                  Editor.Feature_Search_Results
                    .Reconcile_Search_Results_After_Row_Change
                      (S.Feature_Search_Results, S.Feature_Panel,
                       Select_First_When_Available => True);
                  Editor.Panels.Set_Bottom_Content
                    (S.Panels, Editor.Panels.Search_Results_Content);
                  Editor.Panels.Set_Visible
                    (S.Panels, Editor.Panels.Bottom_Panel, True);
                  if Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
                     Editor.Focus_Management.Set_Focus_Owner
                       (S, Editor.Focus_Management.Focus_Project_Search_Results);
                  end if;
                  Editor.Panels.Set_Current (S.Panels);
                  Report_Info
                    (S,
                     "References for " & Name & ":" &
                     Natural'Image (Natural (Result.Targets.Length)) & ".");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info
                 (S, "References unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when Editor.Commands.Command_Workspace_Symbols =>
            declare
               Result : constant Editor.Ada_Language_Service.Language_Target_Set :=
                 Semantic_Workspace_Symbols (S.Language_Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  Editor.Feature_Search_Results.Begin_External_Result_Set
                    (S.Feature_Search_Results,
                     Query        => "symbols: " & Name,
                     Source_Label => "Ada workspace symbols");

                  for Target of Result.Targets loop
                     declare
                        Path   : constant String := To_String (Target.Target.Path);
                        Line   : constant Natural := Target.Target.Line;
                        Column : constant Natural := Target.Target.Column;
                        Symbol_Name : constant String := To_String (Target.Name);
                        Label  : constant String :=
                          Symbol_Name & " at " & Path & ":" &
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
                           Match_Length  => Symbol_Name'Length);
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
                  if Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
                     Editor.Focus_Management.Set_Focus_Owner
                       (S, Editor.Focus_Management.Focus_Project_Search_Results);
                  end if;
                  Editor.Panels.Set_Current (S.Panels);
                  Report_Info
                    (S,
                     "Workspace symbols for " & Name & ":" &
                     Natural'Image (Natural (Result.Targets.Length)) & ".");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info
                 (S, "Workspace symbols unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when Editor.Commands.Command_Show_Hover =>
            declare
               Result : constant Editor.Ada_Language_Service.Hover_Result :=
                 Semantic_Hover (S, S.Language_Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  declare
                     Anchor_Row : Natural := 0;
                     Anchor_Col : Natural := 0;
                     Path   : constant String := To_String (Result.Target.Path);
                     Line   : constant Natural := Result.Target.Line;
                     Column : constant Natural := Result.Target.Column;
                     Detail : constant String := To_String (Result.Detail);
                     Label  : constant String :=
                       "hover " & To_String (Result.Label) &
                       (if Detail'Length > 0 then " - " & Detail else "") &
                       " at " & Path & ":" &
                       Ada.Strings.Fixed.Trim
                         (Natural'Image (Line), Ada.Strings.Both) &
                       ":" &
                       Ada.Strings.Fixed.Trim
                         (Natural'Image (Column), Ada.Strings.Both);
                  begin
                     Editor.State.Row_Col_For_Index
                       (S, Safe_Caret, Anchor_Row, Anchor_Col);
                     S.Semantic_Popup :=
                       (Active => True,
                        Kind => Editor.State.Semantic_Hover_Popup,
                        Anchor_Row => Anchor_Row,
                        Anchor_Column => Anchor_Col,
                        Title => Result.Label,
                        Detail => Result.Detail,
                        Item_Count => 0,
                        Selected_Item => 0,
                        Items => (others => (others => <>)));
                     Editor.Feature_Search_Results.Begin_External_Result_Set
                       (S.Feature_Search_Results,
                        Query        => "hover: " & Name,
                        Source_Label => "Ada semantic hover");
                     Editor.Feature_Search_Results.Add_Search_Result
                       (S.Feature_Search_Results,
                        Label         => Label,
                        Source_Label  => Path,
                        Has_Target    => Result.Key.Buffer_Token /= 0,
                        Target_Buffer => Result.Key.Buffer_Token,
                        Target_Line   => Line,
                        Target_Column => Column,
                        Query         => Name,
                        Match_Line    => Line,
                        Match_Column  => Column,
                        Match_Length  => Name'Length);
                     Editor.Feature_Search_Results
                       .Reconcile_Search_Results_After_Row_Change
                         (S.Feature_Search_Results, S.Feature_Panel,
                          Select_First_When_Available => True);
                  end;
                  Report_Info
                    (S,
                     "Hover: " & To_String (Result.Label) &
                     (if Length (Result.Detail) > 0
                      then " - " & To_String (Result.Detail)
                      else "") & ".");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info
                 (S, "Hover unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when Editor.Commands.Command_Show_Completions =>
            declare
               Result : constant Editor.Ada_Language_Service.Completion_Result :=
                 Semantic_Complete (S, S.Language_Service, Name, 20);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  declare
                     Anchor_Row : Natural := 0;
                     Anchor_Col : Natural := 0;
                     Popup : Editor.State.Semantic_Popup_State;
                     Row : Natural := 0;
                  begin
                     Editor.State.Row_Col_For_Index
                       (S, Safe_Caret, Anchor_Row, Anchor_Col);
                     Popup.Active := True;
                     Popup.Kind := Editor.State.Semantic_Completion_Popup;
                     Popup.Anchor_Row := Anchor_Row;
                     Popup.Anchor_Column := Anchor_Col;
                     Popup.Title := To_Unbounded_String ("Completions for " & Name);
                     Popup.Selected_Item :=
                       (if Result.Items.Length > 0 then 1 else 0);
                     for Item of Result.Items loop
                        exit when Row >= Editor.State.Max_Semantic_Completion_Items;
                        Row := Row + 1;
                        Popup.Items (Editor.State.Semantic_Completion_Item_Index (Row)) :=
                          (Label  => Item.Label,
                           Detail => Item.Detail);
                     end loop;
                     Popup.Item_Count := Row;
                     S.Semantic_Popup := Popup;
                  end;

                  Editor.Feature_Search_Results.Begin_External_Result_Set
                    (S.Feature_Search_Results,
                     Query        => "completions: " & Name,
                     Source_Label => "Ada semantic completions");

                  for Item of Result.Items loop
                     declare
                        Path   : constant String := To_String (Item.Target.Path);
                        Line   : constant Natural := Item.Target.Line;
                        Column : constant Natural := Item.Target.Column;
                        Item_Label : constant String := To_String (Item.Label);
                        Detail : constant String := To_String (Item.Detail);
                        Label  : constant String :=
                          Item_Label &
                          (if Detail'Length > 0 then " - " & Detail else "") &
                          " at " & Path & ":" &
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
                           Has_Target    => Item.Key.Buffer_Token /= 0,
                           Target_Buffer => Item.Key.Buffer_Token,
                           Target_Line   => Line,
                           Target_Column => Column,
                           Query         => Name,
                           Match_Line    => Line,
                           Match_Column  => Column,
                           Match_Length  => Item_Label'Length);
                     end;
                  end loop;

                  Editor.Feature_Search_Results
                    .Reconcile_Search_Results_After_Row_Change
                      (S.Feature_Search_Results, S.Feature_Panel,
                       Select_First_When_Available => True);
                  Report_Info
                    (S,
                     "Completions for " & Name & ":" &
                     Natural'Image (Natural (Result.Items.Length)) & ".");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info
                 (S, "Completions unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Semantic_Service_Command;

end Editor.Executor.Semantic_Service_Commands;
