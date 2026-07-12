with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Commands;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Dirty_Guards;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Editor.Project;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Feature_Messages;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Panels;
use type Editor.Panels.Bottom_Panel_Content;
with Editor.Pending_Transitions;
with Editor.Problems;
with Editor.Recent_Buffers;
with Editor.Render_Cache;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.Shared_Services;
with Editor.State;
use type Editor.State.Dirty_Close_Scope;

package body Editor.Executor.Buffer_Close_Prompt_Commands is

   function Natural_Text
     (Value : Natural) return String
   is
      Image : constant String := Natural'Image (Value);
   begin
      return Image (Image'First + 1 .. Image'Last);
   end Natural_Text;

   procedure Clear_Dirty_Close_Prompt
     (S : in out Editor.State.State_Type)
   is
   begin
      S.Dirty_Close_Prompt_Active := False;
      S.Dirty_Close_Prompt_Scope := Editor.State.No_Dirty_Close_Scope;
      S.Dirty_Close_Prompt_All_Buffers := False;
      S.Dirty_Close_Prompt_Buffer := 0;
      S.Dirty_Close_Prompt_Buffer_Count := 0;
      S.Dirty_Close_Prompt_Buffer_Fingerprint := 0;
      S.Dirty_Close_Prompt_Buffer_Ids :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      S.Dirty_Close_Prompt_Dirty_Fingerprint := 0;
      S.Dirty_Close_Prompt_Dirty_Buffer_Ids :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      S.Dirty_Close_Prompt_Dirty_Count := 0;
      S.Dirty_Close_Prompt_File_Backed_Count := 0;
      S.Dirty_Close_Prompt_Untitled_Count := 0;
      S.Dirty_Close_Prompt_Conflicted_Count := 0;
      S.Dirty_Close_Prompt_Unwritable_Count := 0;
      S.Dirty_Close_Prompt_Missing_Count := 0;
      S.Dirty_Close_Prompt_Save_Failure_Count := 0;
   end Clear_Dirty_Close_Prompt;

   procedure Finalize_Cleanup_Buffer_Close
     (S          : in out Editor.State.State_Type;
      Id         : Editor.Buffers.Buffer_Id;
      Was_Active : Boolean)
   is
   begin
      Editor.Recent_Buffers.Remove (S.Recent_Buffers, Natural (Id));
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Buffer_Close
        (S, Natural (Id));
      if Was_Active then
         Editor.Feature_Messages.Reset_For_Buffer_Close
           (S.Feature_Messages, Editor.Executor.Active_Feature_Buffer_Token (S));
         Editor.Feature_Search_Results.Reset_For_Buffer_Close
           (S.Feature_Search_Results, Editor.Executor.Active_Feature_Buffer_Token (S));
         Editor.Feature_Panel_Controller.Rebuild_Active_Feature_Projection (S);
      end if;
      if Editor.Buffers.Global_Count = 0
        or else Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer
      then
         S.Active_Buffer_Token := 0;
      else
         declare
            Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
              S.Language_Index;
            Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
              S.Language_Service;
         begin
            Editor.Buffers.Load_Global_Active_Into_State (S);
            S.Language_Index := Saved_Index;
            S.Language_Service := Saved_Service;
         end;
      end if;
      Editor.Executor.Pending_Transition_Policy.Invalidate_Pending_Transition_If_Stale (S);
      if Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
        and then Editor.Panels.Active_Bottom_Content (S.Panels) =
          Editor.Panels.Problems_Content
      then
         declare
            Snapshot : constant Editor.Problems.Problems_Snapshot :=
              Editor.Problems.Build_Snapshot (S.Diagnostics);
         begin
            Editor.Problems.Ensure_Valid_Selection (S.Problems_View, Snapshot);
         end;
      end if;
   end Finalize_Cleanup_Buffer_Close;

   function Dirty_Close_Start_Message
     (All_Buffers : Boolean;
      Summary     : Editor.Dirty_Guards.Dirty_Buffer_Summary) return String
   is
      Message : Unbounded_String := Null_Unbounded_String;
   begin
      if not All_Buffers then
         if Summary.Untitled_Count > 0 then
            return "Discard unsaved scratch buffer?";
         else
            return "Unsaved changes require confirmation.";
         end if;
      end if;

      Append
        (Message,
         Natural_Text (Summary.Dirty_Count)
         & (if Summary.Dirty_Count = 1 then
               " dirty buffer requires confirmation"
            else
               " dirty buffers require confirmation"));
      if Summary.File_Backed_Count > 0 or else Summary.Untitled_Count > 0 then
         Append (Message, " (");
         declare
            Categories : Unbounded_String := Null_Unbounded_String;

            procedure Add
              (Count : Natural;
               Label : String)
            is
            begin
               if Count > 0 then
                  if Length (Categories) > 0 then
                     Append (Categories, ", ");
                  end if;
                  Append (Categories, Natural_Text (Count) & " " & Label);
               end if;
            end Add;
         begin
            Add (Summary.File_Backed_Count, "file-backed");
            Add (Summary.Untitled_Count, "scratch");
            Append (Message, To_String (Categories));
         end;
         Append (Message, ")");
      end if;
      Append (Message, ".");
      return To_String (Message);
   end Dirty_Close_Start_Message;

   function Dirty_Buffer_Summary_For_All_Buffers
     return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return Editor.Buffers.Global_Dirty_Buffer_Summary;
   end Dirty_Buffer_Summary_For_All_Buffers;

   function Dirty_Buffer_Summary_For_All_Buffers
     (Project : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return Editor.Buffers.Global_Categorized_Dirty_Buffer_Summary (Project);
   end Dirty_Buffer_Summary_For_All_Buffers;

   function Dirty_Close_Open_Buffer_Fingerprint return Natural
   is
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Fingerprint : Natural := 0;
   begin
      for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
         declare
            Item : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Item.Id /= Editor.Buffers.No_Buffer then
               Fingerprint := Fingerprint + Natural (Item.Id) * Index;
            end if;
         end;
      end loop;
      return Fingerprint;
   end Dirty_Close_Open_Buffer_Fingerprint;

   function Dirty_Close_Dirty_Buffer_Fingerprint return Natural
   is
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Fingerprint : Natural := 0;
   begin
      for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
         declare
            Item : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Item.Id /= Editor.Buffers.No_Buffer and then Item.Is_Dirty then
               Fingerprint := Fingerprint + Natural (Item.Id) * Index;
            end if;
         end;
      end loop;
      return Fingerprint;
   end Dirty_Close_Dirty_Buffer_Fingerprint;

   function Dirty_Close_Buffer_Id_Token
     (Id : Editor.Buffers.Buffer_Id) return String
   is
   begin
      return "|"
        & Ada.Strings.Fixed.Trim
            (Natural'Image (Natural (Id)), Ada.Strings.Both)
        & "|";
   end Dirty_Close_Buffer_Id_Token;

   function Dirty_Close_Open_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String
   is
      Result : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
   begin
      for Index in 1 .. Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Summary.Id /= Editor.Buffers.No_Buffer then
               Ada.Strings.Unbounded.Append
                 (Result, Dirty_Close_Buffer_Id_Token (Summary.Id));
            end if;
         end;
      end loop;
      return Result;
   end Dirty_Close_Open_Buffer_Id_List;

   function Dirty_Close_Dirty_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String
   is
      Result : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
   begin
      for Index in 1 .. Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Summary.Id /= Editor.Buffers.No_Buffer
              and then Summary.Is_Dirty
            then
               Ada.Strings.Unbounded.Append
                 (Result, Dirty_Close_Buffer_Id_Token (Summary.Id));
            end if;
         end;
      end loop;
      return Result;
   end Dirty_Close_Dirty_Buffer_Id_List;

   function Dirty_Close_Current_Dirty_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean
   is
      Review : constant String :=
        Ada.Strings.Unbounded.To_String
          (S.Dirty_Close_Prompt_Dirty_Buffer_Ids);
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
   begin
      for Index in 1 .. Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Summary.Id /= Editor.Buffers.No_Buffer
              and then Summary.Is_Dirty
              and then Ada.Strings.Fixed.Index
                (Review, Dirty_Close_Buffer_Id_Token (Summary.Id)) = 0
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Dirty_Close_Current_Dirty_Set_Was_Reviewed;

   function Dirty_Close_Current_Dirty_Set_Equals_Review
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Dirty_Close_Dirty_Buffer_Id_List =
        S.Dirty_Close_Prompt_Dirty_Buffer_Ids;
   end Dirty_Close_Current_Dirty_Set_Equals_Review;

   function Dirty_Close_Current_Open_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean
   is
      Review : constant String :=
        Ada.Strings.Unbounded.To_String
          (S.Dirty_Close_Prompt_Buffer_Ids);
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
   begin
      if Editor.Buffers.Global_Count /= S.Dirty_Close_Prompt_Buffer_Count then
         return False;
      end if;

      for Index in 1 .. Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Summary.Id /= Editor.Buffers.No_Buffer
              and then Ada.Strings.Fixed.Index
                (Review, Dirty_Close_Buffer_Id_Token (Summary.Id)) = 0
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Dirty_Close_Current_Open_Set_Was_Reviewed;

   function Dirty_Close_All_Buffer_Identity_Current
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Dirty_Close_Current_Open_Set_Was_Reviewed (S)
        and then Dirty_Close_Open_Buffer_Fingerprint =
          S.Dirty_Close_Prompt_Buffer_Fingerprint;
   end Dirty_Close_All_Buffer_Identity_Current;

   function Dirty_Close_All_Buffer_Review_Current
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Dirty_Close_All_Buffer_Identity_Current (S)
        and then Dirty_Close_Dirty_Buffer_Fingerprint =
          S.Dirty_Close_Prompt_Dirty_Fingerprint
        and then Dirty_Close_Current_Dirty_Set_Equals_Review (S);
   end Dirty_Close_All_Buffer_Review_Current;

   procedure Capture_Dirty_Close_File_State_Counts
     (S           : in out Editor.State.State_Type;
      All_Buffers : Boolean;
      Buffer_Id   : Editor.Buffers.Buffer_Id)
   is
      procedure Include_Summary (Summary : Editor.Buffers.Buffer_Summary) is
      begin
         if Summary.Id = Editor.Buffers.No_Buffer or else not Summary.Is_Dirty then
            return;
         end if;
         if Summary.External_Change_Surfaced then
            S.Dirty_Close_Prompt_Conflicted_Count :=
              S.Dirty_Close_Prompt_Conflicted_Count + 1;
         end if;
         if Summary.Last_Save_Failed then
            S.Dirty_Close_Prompt_Save_Failure_Count :=
              S.Dirty_Close_Prompt_Save_Failure_Count + 1;
         end if;
         if Summary.Unwritable_Target_Surfaced then
            S.Dirty_Close_Prompt_Unwritable_Count :=
              S.Dirty_Close_Prompt_Unwritable_Count + 1;
         end if;
         if Summary.Missing_Target_Surfaced then
            S.Dirty_Close_Prompt_Missing_Count :=
              S.Dirty_Close_Prompt_Missing_Count + 1;
         end if;
      end Include_Summary;
   begin
      S.Dirty_Close_Prompt_Conflicted_Count := 0;
      S.Dirty_Close_Prompt_Unwritable_Count := 0;
      S.Dirty_Close_Prompt_Missing_Count := 0;
      S.Dirty_Close_Prompt_Save_Failure_Count := 0;

      if All_Buffers then
         declare
            Registry : constant Editor.Buffers.Buffer_Registry :=
              Editor.Buffers.Global_Registry_For_UI;
         begin
            for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
               Include_Summary (Editor.Buffers.Summary_At (Registry, Index));
            end loop;
         end;
      elsif Buffer_Id /= Editor.Buffers.No_Buffer
        and then Editor.Buffers.Global_Contains (Buffer_Id)
      then
         Include_Summary (Editor.Buffers.Global_Summary_For (Buffer_Id));
      end if;
   end Capture_Dirty_Close_File_State_Counts;

   procedure Start_Dirty_Close_Prompt
     (S           : in out Editor.State.State_Type;
      Scope       : Editor.State.Dirty_Close_Scope;
      All_Buffers : Boolean;
      Buffer_Id   : Editor.Buffers.Buffer_Id;
      Summary     : Editor.Dirty_Guards.Dirty_Buffer_Summary)
   is
   begin
      S.Dirty_Close_Prompt_Active := True;
      S.Dirty_Close_Prompt_Scope := Scope;
      S.Dirty_Close_Prompt_All_Buffers := All_Buffers;
      S.Dirty_Close_Prompt_Buffer := Natural (Buffer_Id);
      S.Dirty_Close_Prompt_Buffer_Count := Editor.Buffers.Global_Count;
      S.Dirty_Close_Prompt_Buffer_Fingerprint :=
        Dirty_Close_Open_Buffer_Fingerprint;
      S.Dirty_Close_Prompt_Buffer_Ids :=
        Dirty_Close_Open_Buffer_Id_List;
      S.Dirty_Close_Prompt_Dirty_Fingerprint :=
        Dirty_Close_Dirty_Buffer_Fingerprint;
      S.Dirty_Close_Prompt_Dirty_Buffer_Ids :=
        Dirty_Close_Dirty_Buffer_Id_List;
      S.Dirty_Close_Prompt_Dirty_Count := Summary.Dirty_Count;
      S.Dirty_Close_Prompt_File_Backed_Count := Summary.File_Backed_Count;
      S.Dirty_Close_Prompt_Untitled_Count := Summary.Untitled_Count;
      Capture_Dirty_Close_File_State_Counts (S, All_Buffers, Buffer_Id);
      Editor.Executor.Shared_Services.Report_Warning
        (S, Dirty_Close_Start_Message (All_Buffers, Summary));
   end Start_Dirty_Close_Prompt;

   procedure Close_Buffer_By_Discard
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Buffers.Buffer_Id;
      Closed : out Boolean)
   is
      Summary    : Editor.Buffers.Buffer_Summary;
      Was_Active : Boolean := False;
   begin
      Closed := False;
      if Id = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Id)
      then
         return;
      end if;

      Summary := Editor.Buffers.Global_Summary_For (Id);
      Was_Active := Summary.Is_Active;
      Editor.Buffers.Global_Force_Close_Buffer (Id, Closed);
      if Closed then
         Finalize_Cleanup_Buffer_Close (S, Id, Was_Active);
      end if;
   end Close_Buffer_By_Discard;

   procedure Execute_Cancel_Close
     (S : in out Editor.State.State_Type)
   is
   begin
      if not S.Dirty_Close_Prompt_Active then
         Editor.Executor.Shared_Services.Report_Info (S, "No close confirmation pending");
         return;
      end if;
      Clear_Dirty_Close_Prompt (S);
      Editor.Executor.Shared_Services.Report_Info (S, "Close cancelled");
   end Execute_Cancel_Close;

   procedure Force_Close_Buffer_For_Group_Lifecycle
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Buffers.Buffer_Id;
      Closed : out Boolean)
   is
      Was_Active : Boolean := False;
   begin
      Closed := False;
      if Id = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Id)
      then
         return;
      end if;

      Was_Active := Editor.Buffers.Global_Summary_For (Id).Is_Active;

      Editor.Buffers.Global_Force_Close_Buffer (Id, Closed);
      if Closed then
         Finalize_Cleanup_Buffer_Close (S, Id, Was_Active);
      end if;
   end Force_Close_Buffer_For_Group_Lifecycle;

   procedure Execute_Close_All_Buffers_Confirmed
     (S : in out Editor.State.State_Type)
   is
      Closed_Total : Natural := 0;
      Closed       : Boolean := False;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      while Editor.Buffers.Global_Count > 0 loop
         declare
            Registry : constant Editor.Buffers.Buffer_Registry :=
              Editor.Buffers.Global_Registry_For_UI;
            Target : constant Editor.Buffers.Buffer_Id :=
              Editor.Buffers.Summary_At (Registry, 1).Id;
         begin
            exit when Target = Editor.Buffers.No_Buffer;
            Force_Close_Buffer_For_Group_Lifecycle (S, Target, Closed);
            if Closed then
               Closed_Total := Closed_Total + 1;
            else
               exit;
            end if;
         end;
      end loop;

      Editor.Pending_Transitions.Clear (S.Pending_Transitions);
      if Editor.Buffers.Global_Count > 0 then
         Editor.Buffers.Load_Global_Active_Into_State (S);
      else
         S.Active_Buffer_Token := 0;
      end if;
      Editor.Executor.Shared_Services.Report_Info (S, "Closed " & Natural_Text (Closed_Total) & " buffers");
   end Execute_Close_All_Buffers_Confirmed;

   procedure Execute_Close_Other_Buffers_Confirmed
     (S      : in out Editor.State.State_Type;
      Active : Editor.Buffers.Buffer_Id)
   is
      Closed_Total : Natural := 0;
      Closed       : Boolean := False;
      Progress     : Boolean := True;
   begin
      while Progress loop
         Progress := False;
         declare
            Registry : constant Editor.Buffers.Buffer_Registry :=
              Editor.Buffers.Global_Registry_For_UI;
         begin
            for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
               declare
                  Item : constant Editor.Buffers.Buffer_Summary :=
                    Editor.Buffers.Summary_At (Registry, Index);
               begin
                  if Item.Id /= Editor.Buffers.No_Buffer
                    and then Item.Id /= Active
                  then
                     Force_Close_Buffer_For_Group_Lifecycle (S, Item.Id, Closed);
                     if Closed then
                        Closed_Total := Closed_Total + 1;
                        Progress := True;
                        exit;
                     end if;
                  end if;
               end;
            end loop;
         end;
      end loop;

      Editor.Pending_Transitions.Clear (S.Pending_Transitions);
      if Editor.Buffers.Global_Contains (Active) then
         Editor.Buffers.Global_Set_Active_Buffer (Active);
         Editor.Buffers.Load_Global_Active_Into_State (S);
      end if;
      Editor.Executor.Shared_Services.Report_Info (S, "Closed " & Natural_Text (Closed_Total) & " other buffers");
   end Execute_Close_Other_Buffers_Confirmed;

   procedure Execute_Confirm_Close_Discard
     (S : in out Editor.State.State_Type)
   is
      Kept_Total   : Natural := 0;
      Closed_Total : Natural := 0;
      Closed       : Boolean := False;
      Was_All      : Boolean := False;
      Was_Selected : Boolean := False;
   begin
      if not S.Dirty_Close_Prompt_Active then
         Editor.Executor.Shared_Services.Report_Info (S, "No close confirmation pending");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Was_All := S.Dirty_Close_Prompt_All_Buffers;
      Was_Selected :=
        S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope;

      if S.Dirty_Close_Prompt_All_Buffers
        and then not Dirty_Close_All_Buffer_Review_Current (S)
      then
         if not Dirty_Close_All_Buffer_Identity_Current (S)
           or else not Dirty_Close_Current_Dirty_Set_Was_Reviewed (S)
         then
            Clear_Dirty_Close_Prompt (S);
            Editor.Executor.Shared_Services.Report_Warning (S, Editor.Commands.Reason_Close_Review_Stale);
            return;
         end if;
      end if;

      if S.Dirty_Close_Prompt_All_Buffers then
         while Editor.Buffers.Global_Count > 0 loop
            declare
               Id : constant Editor.Buffers.Buffer_Id :=
                 Editor.Buffers.First_Buffer (Editor.Buffers.Global_Registry_For_UI);
            begin
               exit when Id = Editor.Buffers.No_Buffer;
               Close_Buffer_By_Discard (S, Id, Closed);
               if Closed then
                  Closed_Total := Closed_Total + 1;
               else
                  Kept_Total := Kept_Total + 1;
                  exit;
               end if;
            end;
         end loop;
      else
         declare
            Target : constant Editor.Buffers.Buffer_Id :=
              Editor.Buffers.Buffer_Id (S.Dirty_Close_Prompt_Buffer);
         begin
            if Target = Editor.Buffers.No_Buffer
              or else not Editor.Buffers.Global_Contains (Target)
            then
               null;
            else
               Close_Buffer_By_Discard (S, Target, Closed);
               if Closed then
                  Closed_Total := Closed_Total + 1;
               else
                  Kept_Total := 1;
               end if;
            end if;
         end;
      end if;

      Clear_Dirty_Close_Prompt (S);
      if Was_Selected then
         Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher (S);
         Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target (S);
      end if;

      if Editor.Buffers.Global_Count = 0 then
         S.Active_Buffer_Token := 0;
      else
         Editor.Buffers.Load_Global_Active_Into_State (S);
      end if;

      if Kept_Total = 0 then
         if Was_All then
            Editor.Executor.Shared_Services.Report_Info (S, "All buffers closed");
         elsif Closed_Total = 1 then
            Editor.Executor.Shared_Services.Report_Info (S, "Buffer closed");
         else
            Editor.Executor.Shared_Services.Report_Info (S, "No buffers closed");
         end if;
      else
         Editor.Executor.Shared_Services.Report_Error (S, "Could not close buffer");
      end if;
   end Execute_Confirm_Close_Discard;

   procedure Execute_Confirm_Close_Save
     (S : in out Editor.State.State_Type)
   is
      Original_Active : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Failed          : Natural := 0;
      Closed_Count    : Natural := 0;
      Was_All         : Boolean := False;
      Was_Selected    : Boolean := False;
      Closed          : Boolean := False;
   begin
      if not S.Dirty_Close_Prompt_Active then
         Editor.Executor.Shared_Services.Report_Info (S, "No close confirmation pending");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Original_Active := Editor.Buffers.Global_Active_Buffer;
      Was_All := S.Dirty_Close_Prompt_All_Buffers;
      Was_Selected :=
        S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope;

      if S.Dirty_Close_Prompt_All_Buffers
        and then not Dirty_Close_All_Buffer_Review_Current (S)
      then
         if not Dirty_Close_All_Buffer_Identity_Current (S)
           or else not Dirty_Close_Current_Dirty_Set_Was_Reviewed (S)
         then
            Clear_Dirty_Close_Prompt (S);
            Editor.Executor.Shared_Services.Report_Warning (S, Editor.Commands.Reason_Close_Review_Stale);
            return;
         end if;
      end if;

      if S.Dirty_Close_Prompt_All_Buffers then
         declare
            Registry : constant Editor.Buffers.Buffer_Registry :=
              Editor.Buffers.Global_Registry_For_UI;
            Count    : constant Natural := Editor.Buffers.Buffer_Count (Registry);
            type Buffer_Id_Array is array (Positive range <>) of Editor.Buffers.Buffer_Id;
            Targets  : Buffer_Id_Array (1 .. Natural'Max (Count, 1));
            Target_Count : Natural := 0;
         begin
            for Index in 1 .. Count loop
               declare
                  Summary : constant Editor.Buffers.Buffer_Summary :=
                    Editor.Buffers.Summary_At (Registry, Index);
               begin
                  if Summary.Id /= Editor.Buffers.No_Buffer then
                     Target_Count := Target_Count + 1;
                     Targets (Target_Count) := Summary.Id;
                  end if;
               end;
            end loop;

            for Index in 1 .. Target_Count loop
               if Editor.Buffers.Global_Contains (Targets (Index)) then
                  declare
                     Summary : constant Editor.Buffers.Buffer_Summary :=
                       Editor.Buffers.Global_Summary_For (Targets (Index));
                  begin
                     if Summary.Is_Dirty and then not Summary.Has_Path then
                        Failed := Failed + 1;
                     else
                        if Summary.Is_Dirty then
                           Editor.Buffers.Global_Set_Active_Buffer (Targets (Index));
                           Editor.Buffers.Load_Global_Active_Into_State (S);
                           Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
                           if S.File_Conflict_Prompt_Active then
                              S.File_Conflict_Close_After_Overwrite := True;
                              S.File_Conflict_Close_After_Overwrite_Buffer :=
                                Natural (Targets (Index));
                              S.File_Conflict_Close_After_Overwrite_Selected := False;
                              S.File_Conflict_Close_After_Overwrite_All_Buffers := True;
                              Clear_Dirty_Close_Prompt (S);
                              Editor.Executor.Shared_Services.Report_Warning (S, "File conflict requires resolution");
                              return;
                           end if;
                        end if;

                        if Editor.Buffers.Global_Contains (Targets (Index))
                          and then not Editor.Buffers.Global_Summary_For (Targets (Index)).Is_Dirty
                        then
                           Close_Buffer_By_Discard (S, Targets (Index), Closed);
                           if Closed then
                              Closed_Count := Closed_Count + 1;
                           else
                              Failed := Failed + 1;
                           end if;
                        else
                           Failed := Failed + 1;
                        end if;
                     end if;
                  end;
               end if;
            end loop;
         end;
      else
         declare
            Target : constant Editor.Buffers.Buffer_Id :=
              Editor.Buffers.Buffer_Id (S.Dirty_Close_Prompt_Buffer);
         begin
            if not Editor.Buffers.Global_Contains (Target) then
               Clear_Dirty_Close_Prompt (S);
               Editor.Executor.Shared_Services.Report_Info (S, "No buffers closed");
               return;
            elsif not Editor.Buffers.Global_Summary_For (Target).Is_Dirty then
               Close_Buffer_By_Discard (S, Target, Closed);
               if Closed then
                  Closed_Count := Closed_Count + 1;
               else
                  Failed := 1;
               end if;
            elsif not Editor.Buffers.Global_Summary_For (Target).Has_Path then
               S.Dirty_Close_Prompt_Save_Failure_Count := 1;
               Editor.Executor.Shared_Services.Report_Error (S, "Save As required before saving this buffer");
               return;
            else
               Editor.Buffers.Global_Set_Active_Buffer (Target);
               Editor.Buffers.Load_Global_Active_Into_State (S);
               Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
               if S.File_Conflict_Prompt_Active then
                  S.File_Conflict_Close_After_Overwrite := True;
                  S.File_Conflict_Close_After_Overwrite_Buffer := Natural (Target);
                  S.File_Conflict_Close_After_Overwrite_Selected := Was_Selected;
                  S.File_Conflict_Close_After_Overwrite_All_Buffers := False;
                  Clear_Dirty_Close_Prompt (S);
                  if Was_Selected
                    and then Original_Active /= Editor.Buffers.No_Buffer
                    and then Original_Active /= Target
                    and then Editor.Buffers.Global_Contains (Original_Active)
                  then
                     declare
                        Prompt_Active : constant Boolean := S.File_Conflict_Prompt_Active;
                        Prompt_Buffer : constant Natural := S.File_Conflict_Prompt_Buffer;
                        Prompt_Path   : constant Unbounded_String :=
                          S.File_Conflict_Prompt_Path;
                        Prompt_Display : constant Unbounded_String :=
                          S.File_Conflict_Prompt_Display;
                        Prompt_Kind : constant Editor.State.File_Conflict_Kind :=
                          S.File_Conflict_Prompt_Kind;
                        Prompt_Dirty : constant Boolean :=
                          S.File_Conflict_Prompt_Dirty;
                        Prompt_Revision : constant Natural :=
                          S.File_Conflict_Prompt_Buffer_Revision;
                        Prompt_Token_Label : constant Unbounded_String :=
                          S.File_Conflict_Prompt_Token_Label;
                        Resume_Close : constant Boolean :=
                          S.File_Conflict_Close_After_Overwrite;
                        Resume_Buffer : constant Natural :=
                          S.File_Conflict_Close_After_Overwrite_Buffer;
                        Resume_Selected : constant Boolean :=
                          S.File_Conflict_Close_After_Overwrite_Selected;
                        Resume_All : constant Boolean :=
                          S.File_Conflict_Close_After_Overwrite_All_Buffers;
                     begin
                        Editor.Buffers.Global_Set_Active_Buffer (Original_Active);
                        Editor.Buffers.Load_Global_Active_Into_State (S);
                        S.File_Conflict_Prompt_Active := Prompt_Active;
                        S.File_Conflict_Prompt_Buffer := Prompt_Buffer;
                        S.File_Conflict_Prompt_Path := Prompt_Path;
                        S.File_Conflict_Prompt_Display := Prompt_Display;
                        S.File_Conflict_Prompt_Kind := Prompt_Kind;
                        S.File_Conflict_Prompt_Dirty := Prompt_Dirty;
                        S.File_Conflict_Prompt_Buffer_Revision := Prompt_Revision;
                        S.File_Conflict_Prompt_Token_Label := Prompt_Token_Label;
                        S.File_Conflict_Close_After_Overwrite := Resume_Close;
                        S.File_Conflict_Close_After_Overwrite_Buffer := Resume_Buffer;
                        S.File_Conflict_Close_After_Overwrite_Selected := Resume_Selected;
                        S.File_Conflict_Close_After_Overwrite_All_Buffers := Resume_All;
                     end;
                  end if;
                  Editor.Executor.Shared_Services.Report_Warning (S, "File conflict requires resolution");
                  return;
               end if;
               if Editor.Buffers.Global_Contains (Target)
                 and then not Editor.Buffers.Global_Summary_For (Target).Is_Dirty
               then
                  Close_Buffer_By_Discard (S, Target, Closed);
                  if Closed then
                     Closed_Count := Closed_Count + 1;
                  else
                     Failed := 1;
                  end if;
               else
                  Failed := 1;
               end if;
            end if;
         end;
      end if;

      if Failed = 0 then
         Clear_Dirty_Close_Prompt (S);
         if Was_Selected then
            Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher (S);
            Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target (S);
         end if;
      elsif Editor.Buffers.Global_Contains (Original_Active) then
         Editor.Buffers.Global_Set_Active_Buffer (Original_Active);
         Editor.Buffers.Load_Global_Active_Into_State (S);
      end if;

      if Editor.Buffers.Global_Count = 0 then
         S.Active_Buffer_Token := 0;
      elsif Failed = 0 then
         Editor.Buffers.Load_Global_Active_Into_State (S);
      end if;

      if Failed = 0 then
         if Was_All then
            Editor.Executor.Shared_Services.Report_Info (S, "All buffers closed");
         elsif Closed_Count = 1 then
            Editor.Executor.Shared_Services.Report_Info (S, "Buffer closed");
         else
            Editor.Executor.Shared_Services.Report_Info (S, "No buffers closed");
         end if;
      else
         if Was_All then
            declare
               Remaining : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
                 Dirty_Buffer_Summary_For_All_Buffers (S.Project);
            begin
               if Remaining.Dirty_Count > 0 then
                  Start_Dirty_Close_Prompt
                    (S, Editor.State.All_Buffers_Close_Scope, True,
                     Editor.Buffers.No_Buffer, Remaining);
                  S.Dirty_Close_Prompt_Save_Failure_Count := Failed;
               else
                  Clear_Dirty_Close_Prompt (S);
               end if;
            end;
            Editor.Executor.Shared_Services.Report_Error (S, "Save failed; some buffers remain open");
         else
            S.Dirty_Close_Prompt_Save_Failure_Count := Failed;
            Editor.Executor.Shared_Services.Report_Error (S, "Save failed; buffer remains open");
         end if;
      end if;
   end Execute_Confirm_Close_Save;

end Editor.Executor.Buffer_Close_Prompt_Commands;
