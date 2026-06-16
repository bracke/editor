with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Strings;
with Ada.Directories;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Containers.Vectors;
with Editor.State;
with Editor.View;
with Editor.Commands;
with Ada.Unchecked_Deallocation;
with Editor.Messages;
with Editor.Feature_Messages;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Feature_Diagnostics;
with Editor.Outline;
with Editor.Project;
with Editor.File_Tree;
with Editor.Render_Cache;
with Editor.Input_Field;
with Editor.Search;
with Editor.Quick_Open;
with Editor.Buffer_Switcher;
with Editor.Recent_Buffers;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Search_Results;
with Editor.Problems;
with Editor.Panels;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;
with Editor.File_Tree_View;
with Editor.Dirty_Guards;
with Editor.Pending_Transitions;
with Editor.Navigation_History;
with Editor.Gutter_Markers;

package body Editor.Buffers is

   procedure Free_Buffer_State is new Ada.Unchecked_Deallocation
     (Object => Buffer_State,
      Name   => Buffer_State_Access);

   Global_Registry                : Buffer_Registry;
   Global_Owner_Token             : Natural := 0;
   Global_Provisional_Active      : Boolean := False;
   Global_Provisional_Active_Id   : Buffer_Id := No_Buffer;

   Metadata_Label_Max : constant Positive := 160;

   function Metadata_Label_Max_Length return Positive is
   begin
      return Metadata_Label_Max;
   end Metadata_Label_Max_Length;

   function Bounded_Metadata_Label (Value : String) return String is
   begin
      if Value'Length <= Metadata_Label_Max then
         return Value;
      elsif Metadata_Label_Max <= 3 then
         return Value (Value'First .. Value'First + Metadata_Label_Max - 1);
      else
         return Value (Value'First .. Value'First + Metadata_Label_Max - 4) & "...";
      end if;
   end Bounded_Metadata_Label;

   procedure Reset_Registry (Registry : in out Buffer_Registry) is
   begin
      if not Registry.Items.Is_Empty then
         for I in Registry.Items.First_Index .. Registry.Items.Last_Index loop
            declare
               State_To_Free : Buffer_State_Access := Registry.Items (I).State;
            begin
               if State_To_Free /= null then
                  Free_Buffer_State (State_To_Free);
               end if;
            end;
         end loop;
      end if;

      Registry.Items.Clear;
      Registry.Has_Active_Group := False;
      Registry.Active_Group := Null_Unbounded_String;
      Registry.Next_Id := 1;
      Registry.Active := No_Buffer;
   end Reset_Registry;

   function "=" (Left, Right : Buffer_Record) return Boolean is
   begin
      return Left.Id = Right.Id;
   end "=";

   procedure Clear_Buffer_Messages (State : in out Buffer_State);

   --  Buffer registry entries are document snapshots.  Editor-global chrome and
   --  focus/input state must not be restored from an older buffer snapshot when
   --  switching buffers.  Keep those states in the live State object and strip
   --  them from the stored per-buffer copy.
   procedure Strip_Global_UI_State
     (State : in out Buffer_State)
   is
   begin
      Clear_Buffer_Messages (State);
      Editor.Project.Clear (State.Project);
      Editor.File_Tree.Clear (State.File_Tree);
      Editor.File_Tree_View.Clear_View (State.File_Tree_View);
      Editor.Input_Field.Clear (State.Active_Find_Input);
      State.Active_Replace_Prompt := False;
      State.Active_Replace_Text := Null_Unbounded_String;
      State.Active_Replace_Error_Message := Null_Unbounded_String;
      Editor.Quick_Open.Clear (State.Quick_Open);
      Editor.Buffer_Switcher.Clear (State.Buffer_Switcher);
      Editor.Recent_Buffers.Clear (State.Recent_Buffers);
      Editor.Project_Search.Clear (State.Project_Search);
      Editor.Project_Search_Bar.Clear (State.Project_Search_Bar);
      State.Search_Results_View := (Top_Row => 1);
      Editor.Problems.Clear_View (State.Problems_View);
      Editor.Panels.Initialize_Defaults (State.Panels);
      Editor.Panel_Focus.Clear (State.Panel_Focus);
      Editor.Overlay_Focus.Clear (State.Overlay_Focus);
      Editor.Pending_Transitions.Clear (State.Pending_Transitions);
      Editor.Navigation_History.Clear (State.Navigation_History);
      Editor.Feature_Panel.Clear (State.Feature_Panel);
      Editor.Outline.Clear (State.Outline);
      Editor.Feature_Messages.Clear (State.Feature_Messages);
      Editor.Feature_Search_Results.Clear (State.Feature_Search_Results);
      Editor.Feature_Diagnostics.Clear (State.Feature_Diagnostics);
      State.Has_Reopen_Candidate := False;
      State.Reopen_Candidate_Path := Null_Unbounded_String;
      State.Reopen_Candidate_Label := Null_Unbounded_String;
   end Strip_Global_UI_State;

   function Index_Of
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Natural
   is
   begin
      if Registry.Items.Is_Empty then
         return Natural'Last;
      end if;

      for I in Registry.Items.First_Index .. Registry.Items.Last_Index loop
         if Registry.Items (I).Id = Id then
            return I;
         end if;
      end loop;

      return Natural'Last;
   end Index_Of;

   function Group_Exists (Registry : Buffer_Registry; Name : String) return Boolean;

   procedure Normalize_Active_Buffer_Group (Registry : in out Buffer_Registry);

   procedure Clear_Buffer_Messages (State : in out Buffer_State) is
   begin
      Editor.Messages.Clear (State.Messages);
   end Clear_Buffer_Messages;

   function Name_In_Use
     (Registry : Buffer_Registry;
      Name     : String) return Boolean
   is
   begin
      for Item of Registry.Items loop
         if Item.State /= null
           and then To_String (Item.State.File_Info.Display_Name) = Name
         then
            return True;
         end if;
      end loop;

      return False;
   end Name_In_Use;


   function Parent_Name_Of (Path : String) return String is
      Last_Slash : Natural := 0;
      Prev_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = Character'Val (16#5C#) then
            Prev_Slash := Last_Slash;
            Last_Slash := I;
         end if;
      end loop;

      if Last_Slash = 0 then
         return "";
      elsif Prev_Slash = 0 then
         if Last_Slash = Path'First then
            return "/";
         else
            return Path (Path'First .. Last_Slash - 1);
         end if;
      elsif Prev_Slash + 1 <= Last_Slash - 1 then
         return Path (Prev_Slash + 1 .. Last_Slash - 1);
      else
         return "/";
      end if;
   end Parent_Name_Of;

   function Duplicate_Display_Name
     (Registry : Buffer_Registry;
      Name     : String) return Boolean
   is
      Seen : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null
           and then To_String (Item.State.File_Info.Display_Name) = Name
         then
            Seen := Seen + 1;
            if Seen > 1 then
               return True;
            end if;
         end if;
      end loop;

      return False;
   end Duplicate_Display_Name;

   function Untitled_Name (Registry : Buffer_Registry) return String is
      Candidate : Natural := 1;
   begin
      loop
         declare
            Name : constant String :=
              (if Candidate = 1 then "Untitled"
               else "Untitled" & Natural'Image (Candidate));
         begin
            if not Name_In_Use (Registry, Name) then
               return Name;
            end if;
         end;
         Candidate := Candidate + 1;
      end loop;
   end Untitled_Name;

   function Create_Untitled_Buffer
     (Registry : in out Buffer_Registry) return Buffer_Id
   is
      Id     : constant Buffer_Id := Registry.Next_Id;
      State  : constant Buffer_State_Access := new Buffer_State;
      Name   : constant String := Untitled_Name (Registry);
      Rec    : Buffer_Record;
   begin
      Editor.State.Init (State.all);
      State.Active_Buffer_Token := Natural (Id);
      State.File_Info.Display_Name := To_Unbounded_String (Name);
      Clear_Buffer_Messages (State.all);

      Rec.Id := Id;
      Rec.State := State;
      Rec.View := Editor.View.Snapshot;
      Registry.Items.Append (Rec);
      Registry.Next_Id := Registry.Next_Id + 1;
      Registry.Active := Id;
      return Id;
   end Create_Untitled_Buffer;

   function Add_Buffer_From_File
     (Registry     : in out Buffer_Registry;
      Path         : String;
      Display_Name : String;
      Contents     : String) return Buffer_Id
   is
      Id     : constant Buffer_Id := Registry.Next_Id;
      State  : constant Buffer_State_Access := new Buffer_State;
      Rec    : Buffer_Record;
      Snap   : constant Editor.View.View_State := Editor.View.Snapshot;
   begin
      Editor.State.Init (State.all);
      State.Active_Buffer_Token := Natural (Id);
      Editor.State.Replace_Buffer_Contents (State.all, Contents);
      State.File_Info.Has_Path := True;
      State.File_Info.Path := To_Unbounded_String (Path);
      State.File_Info.Display_Name := To_Unbounded_String (Display_Name);
      State.File_Info.Dirty := False;
      State.File_Info.Baseline_Valid := True;
      State.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (State.all);
      Clear_Buffer_Messages (State.all);

      Rec.Id := Id;
      Rec.State := State;
      Rec.View := (Scroll_X => 0,
                      Scroll_Y => 0,
                      Visual_Scroll_X => 0.0,
                      Visual_Scroll_Y => 0.0,
                      User_Scroll_Y_Override => False,
                      Wrap_Mode => Snap.Wrap_Mode);
      Registry.Items.Append (Rec);
      Registry.Next_Id := Registry.Next_Id + 1;
      Registry.Active := Id;
      return Id;
   end Add_Buffer_From_File;

   function Contains
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
   begin
      return Index_Of (Registry, Id) /= Natural'Last;
   end Contains;

   function Active_Buffer
     (Registry : Buffer_Registry) return Buffer_Id
   is
   begin
      return Registry.Active;
   end Active_Buffer;

   procedure Set_Active_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
   begin
      if Contains (Registry, Id) then
         Registry.Active := Id;
      end if;
   end Set_Active_Buffer;

   function Count
     (Registry : Buffer_Registry) return Natural
   is
   begin
      return Natural (Registry.Items.Length);
   end Count;

   function Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
   begin
      return Count (Registry);
   end Buffer_Count;

   function Lifecycle_Display_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
      Base : constant String := Display_Label (Registry, Id);
   begin
      if I = Natural'Last or else Registry.Items (I).State = null then
         return Base;
      end if;

      declare
         File : constant File_Identity := Registry.Items (I).State.File_Info;
      begin
         declare
            Decorated : Unbounded_String := To_Unbounded_String (Base);
         begin
            if Registry.Items (I).Has_Label then
               Append (Decorated, " [label: " & To_String (Registry.Items (I).Label) & "]");
            end if;
            if Registry.Items (I).Pinned then
               Append (Decorated, " [Pinned]");
            end if;
            if Registry.Items (I).Has_Group then
               Append (Decorated, " [group: " & To_String (Registry.Items (I).Group) & "]");
            end if;
            if Registry.Items (I).Has_Note then
               Append (Decorated, " — " & To_String (Registry.Items (I).Note));
            end if;

            if File.Missing_Target_Surfaced then
               return To_String (Decorated) & " — missing target";
            elsif File.External_Change_Surfaced and then File.Dirty then
               return To_String (Decorated) & " — conflict pending";
            elsif File.External_Change_Surfaced then
               return To_String (Decorated) & " — external change";
            elsif File.Unreadable_Target_Surfaced
              or else File.Last_Reload_Failed
              or else File.Last_Revert_Failed
            then
               return To_String (Decorated) & " — unreadable target";
            elsif File.Unwritable_Target_Surfaced then
               return To_String (Decorated) & " — unwritable target";
            elsif File.Dirty and then File.Last_Save_Failed and then File.Has_Path then
               return To_String (Decorated) & " — retry save";
            elsif File.Blocked_Close_Surfaced then
               return To_String (Decorated) & " — close blocked";
            elsif not File.Has_Path then
               return To_String (Decorated) & " — untitled";
            else
               return To_String (Decorated);
            end if;
         end;
      end;
   end Lifecycle_Display_Label;


   function Pure_Normalize_Path (Path : String) return String is
      package Part_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Natural,
         Element_Type => Unbounded_String);

      Parts    : Part_Vectors.Vector;
      Token    : Unbounded_String := Null_Unbounded_String;
      Absolute : Boolean := False;

      procedure Flush_Token is
         T : constant String := To_String (Token);
      begin
         if T'Length = 0 or else T = "." then
            null;
         elsif T = ".." then
            if Absolute then
               if not Parts.Is_Empty then
                  Parts.Delete_Last;
               end if;
            elsif not Parts.Is_Empty
              and then To_String (Parts.Last_Element) /= ".."
            then
               Parts.Delete_Last;
            else
               Parts.Append (Token);
            end if;
         else
            Parts.Append (Token);
         end if;
         Token := Null_Unbounded_String;
      end Flush_Token;

      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Path'Length = 0 then
         return "";
      end if;

      Absolute := Path (Path'First) = '/'
        or else Path (Path'First) = Character'Val (16#5C#);

      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = Character'Val (16#5C#) then
            Flush_Token;
         else
            Append (Token, Path (I));
         end if;
      end loop;
      Flush_Token;

      if Absolute then
         Append (Result, "/");
      end if;

      if not Parts.Is_Empty then
         for I in Parts.First_Index .. Parts.Last_Index loop
            if Length (Result) > 0 and then To_String (Result) /= "/" then
               Append (Result, "/");
            end if;
            Append (Result, To_String (Parts.Element (I)));
         end loop;
      end if;

      if Length (Result) = 0 then
         if Absolute then
            return "/";
         else
            return ".";
         end if;
      end if;

      return To_String (Result);
   exception
      when others =>
         return Path;
   end Pure_Normalize_Path;

   function Pure_Same_Or_Descendant_Path
     (Path : String;
      Root : String) return Boolean
   is
      P : constant String := Pure_Normalize_Path (Path);
      R : constant String := Pure_Normalize_Path (Root);
   begin
      if P = R then
         return R'Length > 0;
      elsif R'Length = 0 or else P'Length <= R'Length then
         return False;
      else
         return P (P'First .. P'First + R'Length - 1) = R
           and then P (P'First + R'Length) = '/';
      end if;
   exception
      when others =>
         return False;
   end Pure_Same_Or_Descendant_Path;

   function Pure_Relative_Path
     (Path : String;
      Root : String) return String
   is
      P : constant String := Pure_Normalize_Path (Path);
      R : constant String := Pure_Normalize_Path (Root);
      Start : Integer := P'First + R'Length + 1;
   begin
      if P = R then
         return ".";
      elsif not Pure_Same_Or_Descendant_Path (P, R) then
         return Path;
      elsif Start <= P'Last then
         return P (Start .. P'Last);
      else
         return ".";
      end if;
   exception
      when others =>
         return Path;
   end Pure_Relative_Path;

   function Classify_Buffer_Ownership
     (Has_Path : Boolean;
      Path     : String;
      Project  : Editor.Project.Project_State) return Buffer_Ownership_Kind
   is
      Has_Project : constant Boolean := Editor.Project.Has_Project (Project);
      Root        : constant String :=
        (if Has_Project then Editor.Project.Root_Path (Project) else "");
   begin
      if not Has_Path then
         return Buffer_Scratch_Unbacked;
      elsif Path'Length = 0 then
         return Buffer_Unknown_File_Backed;
      elsif not Has_Project then
         return Buffer_Missing_Project_Context;
      elsif Pure_Same_Or_Descendant_Path (Path, Root) then
         return Buffer_Project_Owned;
      else
         return Buffer_Outside_Project;
      end if;
   end Classify_Buffer_Ownership;

   function Ownership_Label (Kind : Buffer_Ownership_Kind) return String is
   begin
      case Kind is
         when Buffer_Project_Owned =>
            return "Project file";
         when Buffer_Outside_Project =>
            return "Outside project";
         when Buffer_Scratch_Unbacked =>
            return "No backing file";
         when Buffer_Missing_Project_Context =>
            return "No project open.";
         when Buffer_Unknown_File_Backed =>
            return "Unknown file";
      end case;
   end Ownership_Label;

   function Dirty_Category_Label (Kind : Buffer_Dirty_Category) return String is
   begin
      case Kind is
         when Buffer_Not_Dirty =>
            return "Clean";
         when Buffer_Dirty_Project_File =>
            return "Modified project file";
         when Buffer_Dirty_Outside_Project_File =>
            return "Modified outside-project file";
         when Buffer_Dirty_Scratch =>
            return "Unsaved scratch buffer";
         when Buffer_Dirty_Missing_File =>
            return "Modified missing file";
         when Buffer_Dirty_Conflicted_File =>
            return "Modified conflicted file";
         when Buffer_Dirty_Unwritable_File =>
            return "Modified unwritable file";
      end case;
   end Dirty_Category_Label;

   function Close_Eligibility_Label (Kind : Buffer_Close_Eligibility) return String is
   begin
      case Kind is
         when Buffer_Closable_Clean =>
            return "Closable";
         when Buffer_Requires_Dirty_Confirmation =>
            return "Requires dirty confirmation";
         when Buffer_Requires_Save_As_Or_Discard =>
            return "Requires save-as or discard";
         when Buffer_Requires_Conflict_Resolution_Or_Discard =>
            return "Requires conflict resolution or discard";
         when Buffer_Blocked_By_Pending_Confirmation =>
            return "Blocked by pending confirmation";
         when Buffer_Not_A_Real_Row =>
            return "Not a buffer row";
      end case;
   end Close_Eligibility_Label;

   function Workspace_Persistability_Label
     (Kind : Buffer_Workspace_Persistability) return String
   is
   begin
      case Kind is
         when Buffer_Persistable_File_Reference =>
            return "Persistable file reference";
         when Buffer_Not_Persistable_Scratch =>
            return "Not persistable scratch buffer";
         when Buffer_Not_Persistable_Invalid_Path =>
            return "Not persistable invalid path";
         when Buffer_Not_Persistable_Runtime_Only_Id =>
            return "Not persistable runtime buffer id";
         when Buffer_Not_Persistable_Dirty_Text =>
            return "Not persistable dirty text";
      end case;
   end Workspace_Persistability_Label;

   function Lifecycle_Status_Label_For
     (File : File_Identity) return String
   is
   begin
      if File.Missing_Target_Surfaced then
         return "Missing on disk";
      elsif File.External_Change_Surfaced and then File.Dirty then
         return "Conflict pending";
      elsif File.External_Change_Surfaced then
         return "Changed on disk";
      elsif File.Unreadable_Target_Surfaced
        or else File.Last_Reload_Failed
        or else File.Last_Revert_Failed
      then
         return "Unreadable";
      elsif File.Unwritable_Target_Surfaced then
         return "Unwritable";
      elsif not File.Has_Path then
         return "Scratch";
      elsif File.Dirty then
         return "Modified";
      else
         return "Clean";
      end if;
   end Lifecycle_Status_Label_For;

   function Metadata_For
     (Registry    : Buffer_Registry;
      Project     : Editor.Project.Project_State;
      Id          : Buffer_Id;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Metadata_Snapshot
   is
      I : constant Natural := Index_Of (Registry, Id);
      Result : Buffer_Metadata_Snapshot;
   begin
      if I = Natural'Last or else Registry.Items (I).State = null then
         return Result;
      end if;

      declare
         File       : constant File_Identity := Registry.Items (I).State.File_Info;
         Has_Project : constant Boolean := Editor.Project.Has_Project (Project);
         Root       : constant String :=
           (if Has_Project then Editor.Project.Root_Path (Project) else "");
         Path       : constant String := To_String (File.Path);
         Ownership  : constant Buffer_Ownership_Kind :=
           Classify_Buffer_Ownership (File.Has_Path, Path, Project);
         In_Project : constant Boolean := Ownership = Buffer_Project_Owned;
      begin
         Result.Id := Registry.Items (I).Id;
         Result.Display_Label := To_Unbounded_String
           (Bounded_Metadata_Label (Lifecycle_Display_Label (Registry, Id)));
         Result.Has_File_Path := File.Has_Path;
         if File.Has_Path then
            Result.File_Path := To_Unbounded_String
              (Bounded_Metadata_Label (Pure_Normalize_Path (Path)));
         else
            Result.File_Path := Null_Unbounded_String;
            Result.Has_Scratch_Label := True;
            Result.Scratch_Label := To_Unbounded_String ("No backing file");
         end if;
         Result.Has_Project_Relative_Path := In_Project;
         if In_Project then
            Result.Project_Relative_Path := To_Unbounded_String
              (Bounded_Metadata_Label (Pure_Relative_Path (Path, Root)));
         elsif File.Has_Path and then Has_Project and then Path'Length > 0 then
            Result.Has_Outside_Project_Path_Label := True;
            Result.Outside_Project_Path_Label := To_Unbounded_String
              (Bounded_Metadata_Label (Pure_Normalize_Path (Path)));
         end if;
         Result.Is_Active := Registry.Items (I).Id = Registry.Active;
         Result.Is_Selected := Registry.Items (I).Id = Selected_Id;
         Result.Is_Dirty := File.Dirty;
         Result.Is_Clean := not File.Dirty;
         Result.Is_Scratch := not File.Has_Path;
         Result.Missing_Backing_File := File.Missing_Target_Surfaced;
         Result.External_Conflict := File.External_Change_Surfaced;
         Result.Stale_Backing_State := File.External_Change_Surfaced
           or else File.Missing_Target_Surfaced;
         Result.Unreadable := File.Unreadable_Target_Surfaced
           or else File.Last_Reload_Failed
           or else File.Last_Revert_Failed;
         Result.Unwritable := File.Unwritable_Target_Surfaced or else File.Last_Save_Failed;

         Result.Ownership := Ownership;
         Result.Ownership_Label := To_Unbounded_String (Ownership_Label (Result.Ownership));
         Result.Lifecycle_Status_Label := To_Unbounded_String (Lifecycle_Status_Label_For (File));

         if not File.Dirty then
            Result.Dirty_Category := Buffer_Not_Dirty;
         elsif File.Missing_Target_Surfaced then
            Result.Dirty_Category := Buffer_Dirty_Missing_File;
         elsif File.External_Change_Surfaced then
            Result.Dirty_Category := Buffer_Dirty_Conflicted_File;
         elsif File.Unwritable_Target_Surfaced or else File.Last_Save_Failed then
            Result.Dirty_Category := Buffer_Dirty_Unwritable_File;
         elsif not File.Has_Path then
            Result.Dirty_Category := Buffer_Dirty_Scratch;
         elsif Result.Ownership = Buffer_Project_Owned then
            Result.Dirty_Category := Buffer_Dirty_Project_File;
         else
            Result.Dirty_Category := Buffer_Dirty_Outside_Project_File;
         end if;

         if File.Blocked_Close_Surfaced then
            Result.Close_Eligibility := Buffer_Blocked_By_Pending_Confirmation;
         elsif not File.Dirty then
            Result.Close_Eligibility := Buffer_Closable_Clean;
         elsif File.Missing_Target_Surfaced or else File.External_Change_Surfaced then
            Result.Close_Eligibility := Buffer_Requires_Conflict_Resolution_Or_Discard;
         elsif (not File.Has_Path)
           or else File.Unwritable_Target_Surfaced
           or else File.Last_Save_Failed
           or else File.Unreadable_Target_Surfaced
           or else File.Last_Reload_Failed
           or else File.Last_Revert_Failed
         then
            Result.Close_Eligibility := Buffer_Requires_Save_As_Or_Discard;
         else
            Result.Close_Eligibility := Buffer_Requires_Dirty_Confirmation;
         end if;

         if File.Has_Path and then Path'Length > 0 and then not File.Missing_Target_Surfaced then
            Result.Workspace_Persistability := Buffer_Persistable_File_Reference;
         elsif not File.Has_Path then
            Result.Workspace_Persistability := Buffer_Not_Persistable_Scratch;
         else
            Result.Workspace_Persistability := Buffer_Not_Persistable_Invalid_Path;
         end if;
      end;

      return Result;
   end Metadata_For;



   function Project_Lifecycle_Buffer_Sets
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Buffer_Project_Lifecycle_Sets
   is
      Result : Buffer_Project_Lifecycle_Sets;
   begin
      if Registry.Items.Is_Empty then
         return Result;
      end if;

      for Item of Registry.Items loop
         if Item.State /= null then
            declare
               M : constant Buffer_Metadata_Snapshot :=
                 Metadata_For (Registry, Project, Item.Id);
            begin
               case M.Ownership is
                  when Buffer_Project_Owned =>
                     Result.Project_Owned.Append (Item.Id);
                     Result.Project_Close_Affected.Append (Item.Id);
                     if M.Is_Dirty then
                        Result.Project_Owned_Dirty.Append (Item.Id);
                     else
                        Result.Project_Owned_Clean.Append (Item.Id);
                     end if;

                  when Buffer_Outside_Project =>
                     Result.Outside_Project.Append (Item.Id);
                     Result.Project_Close_Unaffected.Append (Item.Id);

                  when Buffer_Scratch_Unbacked =>
                     Result.Scratch.Append (Item.Id);
                     Result.Project_Close_Unaffected.Append (Item.Id);

                  when Buffer_Missing_Project_Context |
                       Buffer_Unknown_File_Backed =>
                     null;
               end case;
            end;
         end if;
      end loop;

      return Result;
   end Project_Lifecycle_Buffer_Sets;

   function Counted_Label
     (Count    : Natural;
      Singular : String;
      Plural   : String) return String
   is
   begin
      if Count = 1 then
         return Natural'Image (Count) & " " & Singular & ".";
      else
         return Natural'Image (Count) & " " & Plural & ".";
      end if;
   end Counted_Label;

   function Trim_Count_Label (Value : String) return String is
   begin
      if Value'Length > 0 and then Value (Value'First) = ' ' then
         return Value (Value'First + 1 .. Value'Last);
      else
         return Value;
      end if;
   end Trim_Count_Label;

   function Audit_Buffers
     (Registry    : Buffer_Registry;
      Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Audit_Summary
   is
      Result : Buffer_Audit_Summary;
   begin
      Result.Buffer_Count := Count (Registry);
      Result.Active_Buffer_Valid :=
        (Registry.Active = No_Buffer and then Registry.Items.Is_Empty)
        or else Contains (Registry, Registry.Active);
      Result.Selected_Buffer_Valid :=
        Selected_Id = No_Buffer or else Contains (Registry, Selected_Id);

      if not Registry.Items.Is_Empty then
         for Item of Registry.Items loop
            declare
               M : constant Buffer_Metadata_Snapshot :=
                 Metadata_For (Registry, Project, Item.Id, Selected_Id);
            begin
               case M.Ownership is
                  when Buffer_Project_Owned =>
                     Result.Project_Owned_Count := Result.Project_Owned_Count + 1;
                  when Buffer_Outside_Project =>
                     Result.Outside_Project_Count := Result.Outside_Project_Count + 1;
                  when Buffer_Scratch_Unbacked =>
                     Result.Scratch_Count := Result.Scratch_Count + 1;
                  when others =>
                     null;
               end case;

               if M.Missing_Backing_File or else M.External_Conflict then
                  Result.Missing_Or_Conflicted_Count := Result.Missing_Or_Conflicted_Count + 1;
               end if;

               if M.Stale_Backing_State then
                  Result.Stale_Backing_State_Count :=
                    Result.Stale_Backing_State_Count + 1;
               end if;

               if M.Missing_Backing_File
                 or else M.External_Conflict
                 or else M.Unreadable
                 or else M.Unwritable
               then
                  Result.Lifecycle_Problem_Count := Result.Lifecycle_Problem_Count + 1;
               end if;

               if M.Ownership = Buffer_Project_Owned then
                  Result.Project_Close_Affected_Count :=
                    Result.Project_Close_Affected_Count + 1;
               elsif M.Ownership = Buffer_Outside_Project
                 or else M.Ownership = Buffer_Scratch_Unbacked
               then
                  Result.Project_Close_Unaffected_Count :=
                    Result.Project_Close_Unaffected_Count + 1;
               end if;

               if M.Unreadable then
                  Result.Unreadable_Count := Result.Unreadable_Count + 1;
               end if;

               if M.Unwritable then
                  Result.Unwritable_Count := Result.Unwritable_Count + 1;
               end if;

               case M.Ownership is
                  when Buffer_Project_Owned =>
                     if M.Is_Dirty then
                        Result.Project_Owned_Dirty_Count := Result.Project_Owned_Dirty_Count + 1;
                     else
                        Result.Project_Owned_Clean_Count := Result.Project_Owned_Clean_Count + 1;
                     end if;
                  when Buffer_Outside_Project =>
                     if M.Is_Dirty then
                        Result.Outside_Project_Dirty_Count := Result.Outside_Project_Dirty_Count + 1;
                     else
                        Result.Outside_Project_Clean_Count := Result.Outside_Project_Clean_Count + 1;
                     end if;
                  when Buffer_Scratch_Unbacked =>
                     if M.Is_Dirty then
                        Result.Scratch_Dirty_Count := Result.Scratch_Dirty_Count + 1;
                     else
                        Result.Scratch_Clean_Count := Result.Scratch_Clean_Count + 1;
                     end if;
                  when others =>
                     null;
               end case;

               case M.Close_Eligibility is
                  when Buffer_Closable_Clean =>
                     Result.Close_Direct_Count := Result.Close_Direct_Count + 1;
                  when Buffer_Requires_Dirty_Confirmation =>
                     Result.Close_Needs_Confirmation_Count :=
                       Result.Close_Needs_Confirmation_Count + 1;
                  when Buffer_Requires_Save_As_Or_Discard =>
                     Result.Close_Needs_Save_As_Count :=
                       Result.Close_Needs_Save_As_Count + 1;
                  when Buffer_Requires_Conflict_Resolution_Or_Discard =>
                     Result.Close_Needs_Conflict_Count :=
                       Result.Close_Needs_Conflict_Count + 1;
                  when Buffer_Blocked_By_Pending_Confirmation =>
                     Result.Close_Blocked_Count := Result.Close_Blocked_Count + 1;
                  when Buffer_Not_A_Real_Row =>
                     null;
               end case;

               case M.Dirty_Category is
                  when Buffer_Dirty_Project_File =>
                     Result.Dirty_Project_File_Count := Result.Dirty_Project_File_Count + 1;
                  when Buffer_Dirty_Outside_Project_File =>
                     Result.Dirty_Outside_Project_Count := Result.Dirty_Outside_Project_Count + 1;
                  when Buffer_Dirty_Scratch =>
                     Result.Dirty_Scratch_Count := Result.Dirty_Scratch_Count + 1;
                  when Buffer_Dirty_Missing_File =>
                     Result.Dirty_Missing_Count := Result.Dirty_Missing_Count + 1;
                  when Buffer_Dirty_Conflicted_File =>
                     Result.Dirty_Conflicted_Count := Result.Dirty_Conflicted_Count + 1;
                  when Buffer_Dirty_Unwritable_File =>
                     Result.Dirty_Unwritable_Count := Result.Dirty_Unwritable_Count + 1;
                  when Buffer_Not_Dirty =>
                     null;
               end case;

               if M.Workspace_Persistability = Buffer_Persistable_File_Reference then
                  Result.Workspace_Persistable_Count := Result.Workspace_Persistable_Count + 1;
               else
                  Result.Workspace_Not_Persistable_Count :=
                    Result.Workspace_Not_Persistable_Count + 1;
               end if;
            end;
         end loop;
      end if;

      declare
         Sets : constant Buffer_Project_Lifecycle_Sets :=
           Project_Lifecycle_Buffer_Sets (Registry, Project);
      begin
         Result.Project_Owned_Count := Natural (Sets.Project_Owned.Length);
         Result.Outside_Project_Count := Natural (Sets.Outside_Project.Length);
         Result.Scratch_Count := Natural (Sets.Scratch.Length);
         Result.Project_Close_Affected_Count :=
           Natural (Sets.Project_Close_Affected.Length);
         Result.Project_Close_Unaffected_Count :=
           Natural (Sets.Project_Close_Unaffected.Length);
         Result.Project_Owned_Dirty_Count := Natural (Sets.Project_Owned_Dirty.Length);
         Result.Project_Owned_Clean_Count := Natural (Sets.Project_Owned_Clean.Length);
      end;

      Result.Dirty_Project_Files_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Project_Owned_Dirty_Count,
             "dirty project file",
             "dirty project files")));
      Result.Dirty_Outside_Project_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Outside_Project_Dirty_Count,
             "dirty outside-project file",
             "dirty outside-project files")));
      Result.Dirty_Scratch_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Scratch_Dirty_Count,
             "unsaved scratch buffer",
             "unsaved scratch buffers")));
      Result.Dirty_File_Conflict_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Dirty_Missing_Count + Result.Dirty_Conflicted_Count,
             "dirty buffer has file conflict",
             "dirty buffers have file conflicts")));
      Result.Workspace_Persistability_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Workspace_Persistable_Count,
             "workspace-persistable file reference",
             "workspace-persistable file references"))
         & " "
         & Trim_Count_Label
             (Counted_Label
               (Result.Workspace_Not_Persistable_Count,
                "runtime-only buffer excluded",
                "runtime-only buffers excluded")));
      Result.Project_Lifecycle_Buffer_Set_Summary_Label := To_Unbounded_String
        (Trim_Count_Label
          (Counted_Label
            (Result.Project_Close_Affected_Count,
             "project-close affected buffer",
             "project-close affected buffers"))
         & " "
         & Trim_Count_Label
             (Counted_Label
               (Result.Project_Close_Unaffected_Count,
                "retained outside/scratch buffer",
                "retained outside/scratch buffers")));

      --  The current command/keybinding/render/persistence models have no
      --  buffer-payload fields.  Keep these explicit audit flags false so
      --  tests can assert the non-leak boundary without executing routes.
      Result.Active_Runtime_Id_Persisted := False;
      Result.Selected_Runtime_Id_Persisted := False;
      Result.Buffer_List_State_Persisted := False;
      Result.Dirty_Text_Persisted := False;
      Result.Scratch_Text_Persisted := False;
      Result.Conflict_Token_Persisted := False;
      Result.Runtime_Buffer_Id_Persisted := False;
      Result.Command_Or_Keybinding_Payload := False;
      Result.Render_Mutation_Route := False;
      Result.Metadata_Projection_Coherent :=
        Result.Active_Buffer_Valid
        and then Result.Selected_Buffer_Valid
        and then (Result.Close_Direct_Count
          + Result.Close_Needs_Confirmation_Count
          + Result.Close_Needs_Save_As_Count
          + Result.Close_Needs_Conflict_Count
          + Result.Close_Blocked_Count = Result.Buffer_Count)
        and then (Result.Workspace_Persistable_Count
          + Result.Workspace_Not_Persistable_Count = Result.Buffer_Count);
      Result.Workspace_Persistence_Safe :=
        not Result.Active_Runtime_Id_Persisted
        and then not Result.Selected_Runtime_Id_Persisted
        and then not Result.Buffer_List_State_Persisted
        and then not Result.Dirty_Text_Persisted
        and then not Result.Scratch_Text_Persisted
        and then not Result.Conflict_Token_Persisted
        and then not Result.Runtime_Buffer_Id_Persisted;
      Result.Command_Keybinding_Payloads_Clear :=
        not Result.Command_Or_Keybinding_Payload;
      Result.Render_Boundary_Safe := not Result.Render_Mutation_Route;
      Result.Audit_Side_Effect_Free := True;
      return Result;
   end Audit_Buffers;

   function Buffer_Metadata_Lifecycle_Audit_Coherent
     (Registry    : Buffer_Registry;
      Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Boolean
   is
      Audit : constant Buffer_Audit_Summary :=
        Audit_Buffers (Registry, Project, Selected_Id);
   begin
      return Audit.Metadata_Projection_Coherent
        and then Audit.Workspace_Persistence_Safe
        and then Audit.Command_Keybinding_Payloads_Clear
        and then Audit.Render_Boundary_Safe
        and then Audit.Audit_Side_Effect_Free;
   end Buffer_Metadata_Lifecycle_Audit_Coherent;

   function Project_Owned_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural
   is
   begin
      return Audit_Buffers (Registry, Project).Project_Owned_Count;
   end Project_Owned_Buffer_Count;

   function Outside_Project_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural
   is
   begin
      return Audit_Buffers (Registry, Project).Outside_Project_Count;
   end Outside_Project_Buffer_Count;

   function Scratch_Buffer_Count (Registry : Buffer_Registry) return Natural is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null and then not Item.State.File_Info.Has_Path then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Scratch_Buffer_Count;

   function Project_Owned_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural
   is
   begin
      return Audit_Buffers (Registry, Project).Project_Owned_Dirty_Count;
   end Project_Owned_Dirty_Buffer_Count;

   function Outside_Project_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural
   is
   begin
      return Audit_Buffers (Registry, Project).Outside_Project_Dirty_Count;
   end Outside_Project_Dirty_Buffer_Count;

   function Scratch_Dirty_Buffer_Count
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State) return Natural
   is
   begin
      return Audit_Buffers (Registry, Project).Scratch_Dirty_Count;
   end Scratch_Dirty_Buffer_Count;

   function Categorized_Dirty_Buffer_Summary
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
      Audit : constant Buffer_Audit_Summary := Audit_Buffers (Registry, Project);
      Dirty : constant Natural :=
        Audit.Dirty_Project_File_Count
        + Audit.Dirty_Outside_Project_Count
        + Audit.Dirty_Scratch_Count
        + Audit.Dirty_Missing_Count
        + Audit.Dirty_Conflicted_Count
        + Audit.Dirty_Unwritable_Count;
   begin
      return
        (Dirty_Count       => Dirty,
         Untitled_Count    => Audit.Dirty_Scratch_Count,
         File_Backed_Count => Dirty - Audit.Dirty_Scratch_Count);
   end Categorized_Dirty_Buffer_Summary;

   function Project_Lifecycle_Dirty_Buffer_Summary
     (Registry : Buffer_Registry;
      Project  : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
      Audit : constant Buffer_Audit_Summary := Audit_Buffers (Registry, Project);
   begin
      return
        (Dirty_Count       => Audit.Project_Owned_Dirty_Count,
         Untitled_Count    => 0,
         File_Backed_Count => Audit.Project_Owned_Dirty_Count);
   end Project_Lifecycle_Dirty_Buffer_Summary;

   function Summary_For
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Buffer_Summary
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else Registry.Items (I).State = null then
         return (Id           => No_Buffer,
                 Display_Name => Null_Unbounded_String,
                 Is_Dirty     => False,
                 Is_Active    => False,
                 Has_Path     => False,
                 Path         => Null_Unbounded_String,
                 Last_Save_Failed => False,
                 Last_Reload_Failed => False,
                 Last_Revert_Failed => False,
                 Missing_Target_Surfaced => False,
                 Unreadable_Target_Surfaced => False,
                 Unwritable_Target_Surfaced => False,
                 External_Change_Surfaced => False,
                 Blocked_Close_Surfaced  => False,
                 Is_Pinned               => False,
                 Has_Group               => False,
                 Group_Name              => Null_Unbounded_String,
                 Has_Label               => False,
                 Label_Text              => Null_Unbounded_String,
                 Has_Note                => False,
                 Note_Text               => Null_Unbounded_String);
      end if;

      return (Id           => Registry.Items (I).Id,
              Display_Name => To_Unbounded_String
                (Lifecycle_Display_Label (Registry, Registry.Items (I).Id)),
              Is_Dirty     => Registry.Items (I).State.File_Info.Dirty,
              Is_Active    => Registry.Items (I).Id = Registry.Active,
              Has_Path     => Registry.Items (I).State.File_Info.Has_Path,
              Path         => Registry.Items (I).State.File_Info.Path,
              Last_Save_Failed => Registry.Items (I).State.File_Info.Last_Save_Failed,
              Last_Reload_Failed => Registry.Items (I).State.File_Info.Last_Reload_Failed,
              Last_Revert_Failed => Registry.Items (I).State.File_Info.Last_Revert_Failed,
              Missing_Target_Surfaced => Registry.Items (I).State.File_Info.Missing_Target_Surfaced,
              Unreadable_Target_Surfaced => Registry.Items (I).State.File_Info.Unreadable_Target_Surfaced,
              Unwritable_Target_Surfaced => Registry.Items (I).State.File_Info.Unwritable_Target_Surfaced,
              External_Change_Surfaced => Registry.Items (I).State.File_Info.External_Change_Surfaced,
              Blocked_Close_Surfaced  => Registry.Items (I).State.File_Info.Blocked_Close_Surfaced,
              Is_Pinned               => Registry.Items (I).Pinned,
              Has_Group               => Registry.Items (I).Has_Group,
              Group_Name              => Registry.Items (I).Group,
              Has_Label               => Registry.Items (I).Has_Label,
              Label_Text              => Registry.Items (I).Label,
              Has_Note                => Registry.Items (I).Has_Note,
              Note_Text               => Registry.Items (I).Note);
   end Summary_For;

   function Summary_At
     (Registry : Buffer_Registry;
      Index    : Positive) return Buffer_Summary
   is
      Zero_Index : constant Natural := Index - 1;
   begin
      if Registry.Items.Is_Empty
        or else Zero_Index < Registry.Items.First_Index
        or else Zero_Index > Registry.Items.Last_Index
        or else Registry.Items (Zero_Index).State = null
      then
         return (Id           => No_Buffer,
                 Display_Name => Null_Unbounded_String,
                 Is_Dirty     => False,
                 Is_Active    => False,
                 Has_Path     => False,
                 Path         => Null_Unbounded_String,
                 Last_Save_Failed => False,
                 Last_Reload_Failed => False,
                 Last_Revert_Failed => False,
                 Missing_Target_Surfaced => False,
                 Unreadable_Target_Surfaced => False,
                 Unwritable_Target_Surfaced => False,
                 External_Change_Surfaced => False,
                 Blocked_Close_Surfaced  => False,
                 Is_Pinned               => False,
                 Has_Group               => False,
                 Group_Name              => Null_Unbounded_String,
                 Has_Label               => False,
                 Label_Text              => Null_Unbounded_String,
                 Has_Note                => False,
                 Note_Text               => Null_Unbounded_String);
      end if;

      return Summary_For (Registry, Registry.Items (Zero_Index).Id);
   end Summary_At;

   function Is_Empty
     (Registry : Buffer_Registry) return Boolean
   is
   begin
      return Registry.Items.Is_Empty;
   end Is_Empty;

   function Current
     (Registry : Buffer_Registry) return Buffer_State
   is
   begin
      return Buffer (Registry, Registry.Active);
   end Current;

   function Current_Access
     (Registry : in out Buffer_Registry) return access Buffer_State
   is
   begin
      return Buffer_Access (Registry, Registry.Active);
   end Current_Access;

   function Buffer
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Buffer_State
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      pragma Assert (I /= Natural'Last, "invalid buffer id");
      return Registry.Items (I).State.all;
   end Buffer;

   function Buffer_Access
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id) return access Buffer_State
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last then
         return null;
      end if;
      return Registry.Items (I).State;
   end Buffer_Access;

   procedure Close_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Closed   : out Boolean;
      Force    : Boolean := False)
   is
      I          : constant Natural := Index_Of (Registry, Id);
      Was_Active : constant Boolean := Registry.Active = Id;
      New_Active : Buffer_Id := No_Buffer;
   begin
      Closed := False;
      if I = Natural'Last then
         return;
      end if;

      if Registry.Items (I).State.File_Info.Dirty and then not Force then
         return;
      end if;

      if Was_Active and then Registry.Items.Length > 1 then
         if I < Registry.Items.Last_Index then
            New_Active := Registry.Items (I + 1).Id;
         elsif I > Registry.Items.First_Index then
            New_Active := Registry.Items (I - 1).Id;
         end if;
      elsif not Was_Active then
         New_Active := Registry.Active;
      end if;

      declare
         State_To_Free : Buffer_State_Access := Registry.Items (I).State;
      begin
         --  Phase 432: canonical active-buffer close owns no close history or
         --  reopen stack.  Closing removes the buffer-local state and makes it
         --  unreachable through open-buffer APIs; it does not persist or cache
         --  a last-closed target, discarded text, caret, view, or path.
         if State_To_Free /= null then
            Free_Buffer_State (State_To_Free);
         end if;
      end;

      Registry.Items.Delete (I);
      Closed := True;

      if Registry.Items.Is_Empty then
         Registry.Active := No_Buffer;
      elsif New_Active /= No_Buffer then
         Registry.Active := New_Active;
      else
         Registry.Active := Registry.Items (Registry.Items.First_Index).Id;
      end if;

      Normalize_Active_Buffer_Group (Registry);
   end Close_Buffer;

   function Normalize_For_Buffer_Path_Compare (Path : String) return String is
      Last   : Integer := Path'Last;
      Result : String (Path'Range);
   begin
      if Path'Length = 0 then
         return Path;
      end if;

      for I in Path'Range loop
         if Path (I) = Character'Val (16#5C#) then
            Result (I) := '/';
         else
            Result (I) := Path (I);
         end if;
      end loop;

      while Last > Result'First and then Result (Last) = '/' loop
         Last := Last - 1;
      end loop;

      return Result (Result'First .. Last);
   end Normalize_For_Buffer_Path_Compare;

   function Canonical_For_Compare (Path : String) return String is
   begin
      --  Phase 545 completeness: File Tree rename/delete buffer-registry
      --  guards must compare paths consistently even when an open buffer was
      --  created from a path spelling that uses backslashes or trailing
      --  separators.  Existing paths are canonicalized through Full_Name; all
      --  paths are then normalized to slash separators before prefix checks.
      if Path'Length > 0 and then Ada.Directories.Exists (Path) then
         return Normalize_For_Buffer_Path_Compare
           (Ada.Directories.Full_Name (Path));
      else
         return Normalize_For_Buffer_Path_Compare (Path);
      end if;
   exception
      when others =>
         return Normalize_For_Buffer_Path_Compare (Path);
   end Canonical_For_Compare;

   function Same_Or_Descendant_Path
     (Path : String;
      Root : String) return Boolean
   is
      P : constant String := Canonical_For_Compare (Path);
      R : constant String := Canonical_For_Compare (Root);
   begin
      if P = R then
         return True;
      elsif R'Length = 0 or else P'Length <= R'Length then
         return False;
      else
         return P (P'First .. P'First + R'Length - 1) = R
           and then (P (P'First + R'Length) = '/'
                     or else P (P'First + R'Length) = Character'Val (16#5C#));
      end if;
   exception
      when others =>
         return False;
   end Same_Or_Descendant_Path;

   function Rebase_Path
     (Path     : String;
      Old_Root : String;
      New_Root : String) return String
   is
      P : constant String := Canonical_For_Compare (Path);
      R : constant String := Canonical_For_Compare (Old_Root);
      Suffix_Start : Integer := P'First + R'Length;
   begin
      if P = R then
         return New_Root;
      elsif R'Length = 0 or else P'Length <= R'Length then
         return Path;
      elsif P (P'First .. P'First + R'Length - 1) /= R then
         return Path;
      elsif P (P'First + R'Length) /= '/'
        and then P (P'First + R'Length) /= Character'Val (16#5C#)
      then
         return Path;
      else
         Suffix_Start := P'First + R'Length + 1;
         return Ada.Directories.Compose
           (New_Root, P (Suffix_Start .. P'Last));
      end if;
   exception
      when others =>
         return Path;
   end Rebase_Path;

   function Find_By_Path
     (Registry : Buffer_Registry;
      Path     : String;
      Found    : out Boolean) return Buffer_Id
   is
      Query_Path : constant String := Canonical_For_Compare (Path);
   begin
      Found := False;
      if Registry.Items.Is_Empty then
         return No_Buffer;
      end if;

      for Item of Registry.Items loop
         if Item.State /= null
           and then Item.State.File_Info.Has_Path
         then
            declare
               Stored_Path : constant String :=
                 To_String (Item.State.File_Info.Path);
            begin
               if Stored_Path = Path
                 or else Stored_Path = Query_Path
                 or else Canonical_For_Compare (Stored_Path) = Query_Path
               then
                  Found := True;
                  return Item.Id;
               end if;
            end;
         end if;
      end loop;

      return No_Buffer;
   end Find_By_Path;

   function First_Buffer
     (Registry : Buffer_Registry) return Buffer_Id
   is
   begin
      if Registry.Items.Is_Empty then
         return No_Buffer;
      end if;

      return Registry.Items (Registry.Items.First_Index).Id;
   end First_Buffer;

   function Last_Buffer
     (Registry : Buffer_Registry) return Buffer_Id
   is
   begin
      if Registry.Items.Is_Empty then
         return No_Buffer;
      end if;

      return Registry.Items (Registry.Items.Last_Index).Id;
   end Last_Buffer;

   function Next_Buffer
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Buffer_Id
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if Registry.Items.Is_Empty or else I = Natural'Last then
         return No_Buffer;
      elsif Registry.Items.Length = 1 then
         return Id;
      elsif I = Registry.Items.Last_Index then
         return Registry.Items (Registry.Items.First_Index).Id;
      else
         return Registry.Items (I + 1).Id;
      end if;
   end Next_Buffer;

   function Previous_Buffer
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Buffer_Id
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if Registry.Items.Is_Empty or else I = Natural'Last then
         return No_Buffer;
      elsif Registry.Items.Length = 1 then
         return Id;
      elsif I = Registry.Items.First_Index then
         return Registry.Items (Registry.Items.Last_Index).Id;
      else
         return Registry.Items (I - 1).Id;
      end if;
   end Previous_Buffer;

   function Next_Buffer
     (Registry : Buffer_Registry) return Buffer_Id
   is
   begin
      return Next_Buffer (Registry, Registry.Active);
   end Next_Buffer;

   function Previous_Buffer
     (Registry : Buffer_Registry) return Buffer_Id
   is
   begin
      return Previous_Buffer (Registry, Registry.Active);
   end Previous_Buffer;

   function Display_Name
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else Registry.Items (I).State = null then
         return "<invalid buffer>";
      end if;

      return To_String (Registry.Items (I).State.File_Info.Display_Name);
   end Display_Name;

   function Display_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else Registry.Items (I).State = null then
         return "<invalid buffer>";
      end if;

      declare
         Name : constant String :=
           To_String (Registry.Items (I).State.File_Info.Display_Name);
      begin
         if not Duplicate_Display_Name (Registry, Name) then
            return Name;
         elsif Registry.Items (I).State.File_Info.Has_Path then
            declare
               Path   : constant String :=
                 To_String (Registry.Items (I).State.File_Info.Path);
               Parent : constant String := Parent_Name_Of (Path);
            begin
               if Parent'Length > 0 then
                  return Name & " — " & Parent;
               else
                  return Name & " — " & Path;
               end if;
            end;
         else
            return Name & " — buffer " & Buffer_Id'Image (Id);
         end if;
      end;
   end Display_Label;

   function Is_Dirty
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else Registry.Items (I).State = null then
         return False;
      end if;

      return Registry.Items (I).State.File_Info.Dirty;
   end Is_Dirty;

   function Is_File_Backed
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else Registry.Items (I).State = null then
         return False;
      end if;

      return Registry.Items (I).State.File_Info.Has_Path;
   end Is_File_Backed;

   function Is_Buffer_Pinned
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      return I /= Natural'Last and then Registry.Items (I).Pinned;
   end Is_Buffer_Pinned;

   function Trimmed_Group_Name (Name : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Name, Ada.Strings.Both);
   end Trimmed_Group_Name;

   function Trimmed_Buffer_Label (Label : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Label, Ada.Strings.Both);
   end Trimmed_Buffer_Label;

   function Has_Buffer_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      return I /= Natural'Last and then Registry.Items (I).Has_Label;
   end Has_Buffer_Label;

   function Buffer_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else not Registry.Items (I).Has_Label then
         return "";
      end if;
      return To_String (Registry.Items (I).Label);
   end Buffer_Label;

   procedure Set_Buffer_Label
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Label    : String)
   is
      I : constant Natural := Index_Of (Registry, Id);
      Trimmed : constant String := Trimmed_Buffer_Label (Label);
   begin
      if I /= Natural'Last then
         if Trimmed'Length = 0 then
            Clear_Buffer_Label (Registry, Id);
         elsif Trimmed'Length <= Max_Buffer_Label_Length then
            Registry.Items (I).Has_Label := True;
            Registry.Items (I).Label := To_Unbounded_String (Trimmed);
         end if;
      end if;
   end Set_Buffer_Label;

   procedure Clear_Buffer_Label
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Has_Label := False;
         Registry.Items (I).Label := Null_Unbounded_String;
      end if;
   end Clear_Buffer_Label;

   function Trimmed_Buffer_Note (Note : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Note, Ada.Strings.Both);
   end Trimmed_Buffer_Note;

   function Has_Buffer_Note
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      return I /= Natural'Last and then Registry.Items (I).Has_Note;
   end Has_Buffer_Note;

   function Buffer_Note
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else not Registry.Items (I).Has_Note then
         return "";
      end if;
      return To_String (Registry.Items (I).Note);
   end Buffer_Note;

   procedure Set_Buffer_Note
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Note     : String)
   is
      I : constant Natural := Index_Of (Registry, Id);
      Trimmed : constant String := Trimmed_Buffer_Note (Note);
   begin
      if I /= Natural'Last then
         if Trimmed'Length = 0 then
            Clear_Buffer_Note (Registry, Id);
         elsif Trimmed'Length <= Max_Buffer_Note_Length then
            Registry.Items (I).Has_Note := True;
            Registry.Items (I).Note := To_Unbounded_String (Trimmed);
         end if;
      end if;
   end Set_Buffer_Note;

   procedure Clear_Buffer_Note
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Has_Note := False;
         Registry.Items (I).Note := Null_Unbounded_String;
      end if;
   end Clear_Buffer_Note;

   function Has_Buffer_Group
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      return I /= Natural'Last and then Registry.Items (I).Has_Group;
   end Has_Buffer_Group;

   function Buffer_Group
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else not Registry.Items (I).Has_Group then
         return "";
      end if;
      return To_String (Registry.Items (I).Group);
   end Buffer_Group;

   procedure Assign_Buffer_Group
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Name     : String)
   is
      I : constant Natural := Index_Of (Registry, Id);
      Trimmed : constant String := Trimmed_Group_Name (Name);
   begin
      if I /= Natural'Last and then Trimmed'Length > 0 then
         Registry.Items (I).Has_Group := True;
         Registry.Items (I).Group := To_Unbounded_String (Trimmed);
      end if;
   end Assign_Buffer_Group;

   procedure Clear_Buffer_Group
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Has_Group := False;
         Registry.Items (I).Group := Null_Unbounded_String;
         Normalize_Active_Buffer_Group (Registry);
      end if;
   end Clear_Buffer_Group;

   function Has_Buffer_Groups
     (Registry : Buffer_Registry) return Boolean
   is
   begin
      for Item of Registry.Items loop
         if Item.Has_Group then
            return True;
         end if;
      end loop;
      return False;
   end Has_Buffer_Groups;

   function Has_Active_Buffer_Group
     (Registry : Buffer_Registry) return Boolean
   is
   begin
      return Registry.Has_Active_Group;
   end Has_Active_Buffer_Group;

   function Active_Buffer_Group
     (Registry : Buffer_Registry) return String
   is
   begin
      if not Registry.Has_Active_Group then
         return "";
      end if;
      return To_String (Registry.Active_Group);
   end Active_Buffer_Group;

   function Group_Exists (Registry : Buffer_Registry; Name : String) return Boolean is
      Trimmed : constant String := Trimmed_Group_Name (Name);
   begin
      for Item of Registry.Items loop
         if Item.Has_Group and then To_String (Item.Group) = Trimmed then
            return True;
         end if;
      end loop;
      return False;
   end Group_Exists;

   procedure Normalize_Active_Buffer_Group (Registry : in out Buffer_Registry) is
   begin
      if Registry.Has_Active_Group
        and then not Group_Exists (Registry, To_String (Registry.Active_Group))
      then
         Registry.Has_Active_Group := False;
         Registry.Active_Group := Null_Unbounded_String;
      end if;
   end Normalize_Active_Buffer_Group;

   function First_Buffer_In_Group
     (Registry : Buffer_Registry;
      Name     : String) return Buffer_Id
   is
      Trimmed : constant String := Trimmed_Group_Name (Name);
   begin
      if Trimmed'Length = 0 then
         return No_Buffer;
      end if;

      for Item of Registry.Items loop
         if Item.Has_Group and then To_String (Item.Group) = Trimmed then
            return Item.Id;
         end if;
      end loop;

      return No_Buffer;
   end First_Buffer_In_Group;

   procedure Set_Active_Buffer_Group
     (Registry : in out Buffer_Registry;
      Name     : String)
   is
      Trimmed : constant String := Trimmed_Group_Name (Name);
   begin
      if Trimmed'Length > 0 and then Group_Exists (Registry, Trimmed) then
         Registry.Has_Active_Group := True;
         Registry.Active_Group := To_Unbounded_String (Trimmed);
      end if;
   end Set_Active_Buffer_Group;

   procedure Clear_Active_Buffer_Group
     (Registry : in out Buffer_Registry)
   is
   begin
      Registry.Has_Active_Group := False;
      Registry.Active_Group := Null_Unbounded_String;
   end Clear_Active_Buffer_Group;

   procedure Cycle_Active_Buffer_Group
     (Registry : in out Buffer_Registry;
      Forward  : Boolean)
   is
      package Name_Vectors is new Ada.Containers.Vectors
        (Index_Type => Natural, Element_Type => Unbounded_String);
      Names : Name_Vectors.Vector;
      Current : constant String := Active_Buffer_Group (Registry);
      Current_Index : Natural := Natural'Last;
   begin
      for Item of Registry.Items loop
         if Item.Has_Group then
            declare
               Name : constant String := To_String (Item.Group);
               Seen : Boolean := False;
            begin
               for Existing of Names loop
                  if To_String (Existing) = Name then
                     Seen := True;
                  end if;
               end loop;
               if not Seen then
                  Names.Append (Item.Group);
               end if;
            end;
         end if;
      end loop;
      if Names.Is_Empty then
         return;
      end if;
      for I in Names.First_Index .. Names.Last_Index loop
         if To_String (Names (I)) = Current then
            Current_Index := I;
         end if;
      end loop;
      if Current_Index = Natural'Last then
         Registry.Active_Group := Names (Names.First_Index);
      elsif Forward then
         if Current_Index = Names.Last_Index then
            Registry.Active_Group := Names (Names.First_Index);
         else
            Registry.Active_Group := Names (Current_Index + 1);
         end if;
      else
         if Current_Index = Names.First_Index then
            Registry.Active_Group := Names (Names.Last_Index);
         else
            Registry.Active_Group := Names (Current_Index - 1);
         end if;
      end if;
      Registry.Has_Active_Group := True;
   end Cycle_Active_Buffer_Group;

   function Closeable_Unpinned_Clean_Outside_Active_Group_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
      Group : constant String := Active_Buffer_Group (Registry);
   begin
      if not Registry.Has_Active_Group then
         return 0;
      end if;
      for Item of Registry.Items loop
         if Item.State /= null
           and then not Item.Pinned
           and then not Item.State.File_Info.Dirty
           and then (not Item.Has_Group or else To_String (Item.Group) /= Group)
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Closeable_Unpinned_Clean_Outside_Active_Group_Count;

   procedure Pin_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Pinned := True;
      end if;
   end Pin_Buffer;

   procedure Unpin_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Pinned := False;
      end if;
   end Unpin_Buffer;

   procedure Toggle_Buffer_Pin
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I /= Natural'Last then
         Registry.Items (I).Pinned := not Registry.Items (I).Pinned;
      end if;
   end Toggle_Buffer_Pin;

   function Unpinned_Clean_Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null
           and then not Item.Pinned
           and then not Item.State.File_Info.Dirty
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Unpinned_Clean_Buffer_Count;

   function Dirty_Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null and then Item.State.File_Info.Dirty then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Dirty_Buffer_Count;

   function Dirty_File_Backed_Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null
           and then Item.State.File_Info.Dirty
           and then Item.State.File_Info.Has_Path
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Dirty_File_Backed_Buffer_Count;

   function Dirty_Untitled_Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null
           and then Item.State.File_Info.Dirty
           and then not Item.State.File_Info.Has_Path
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Dirty_Untitled_Buffer_Count;

   function Clean_Buffer_Count
     (Registry : Buffer_Registry) return Natural
   is
      Result : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null and then not Item.State.File_Info.Dirty then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Clean_Buffer_Count;

   function Dirty_Buffer_Display_Name
     (Registry : Buffer_Registry;
      Index    : Positive) return String
   is
      Seen : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null and then Item.State.File_Info.Dirty then
            Seen := Seen + 1;
            if Seen = Index then
               return To_String (Item.State.File_Info.Display_Name);
            end if;
         end if;
      end loop;
      return "<invalid buffer>";
   end Dirty_Buffer_Display_Name;

   function Dirty_Buffer_Summary
     (Registry : Buffer_Registry)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return (Dirty_Count       => Dirty_Buffer_Count (Registry),
              Untitled_Count    => Dirty_Untitled_Buffer_Count (Registry),
              File_Backed_Count => Dirty_File_Backed_Buffer_Count (Registry));
   end Dirty_Buffer_Summary;

   procedure Mark_Global_Provisional_Active is
   begin
      if Global_Registry.Items.Is_Empty
        and then Global_Registry.Active = No_Buffer
      then
         Global_Provisional_Active := True;
         Global_Provisional_Active_Id := Global_Registry.Next_Id;
      end if;
   end Mark_Global_Provisional_Active;

   procedure Ensure_Global_Registry
     (State : in out Editor.State.State_Type)
   is
      Id     : Buffer_Id;
      Rec    : Buffer_Record;
      Copy   : Buffer_State := State;
   begin
      if State.Registry_Token /= Global_Owner_Token then
         Reset_Registry (Global_Registry);
         Global_Owner_Token := State.Registry_Token;
         Editor.History.Undo_Stack.Clear;
         Editor.History.Redo_Stack.Clear;
         if State.Active_Buffer_Token = 0 then
            return;
         end if;
      elsif not Global_Registry.Items.Is_Empty then
         return;
      elsif State.Active_Buffer_Token = 0 then
         --  Phase 430: a deliberate close-last-buffer state must remain
         --  bufferless.  Read/command paths may ensure the registry, but
         --  they must not resurrect the just-closed buffer from stale State.
         return;
      end if;

      Id := Global_Registry.Next_Id;
      Strip_Global_UI_State (Copy);
      Rec.Id := Id;
      Rec.State := new Buffer_State'(Copy);
      Rec.Undo := Editor.History.Undo_Stack;
      Rec.Redo := Editor.History.Redo_Stack;
      Rec.View := Editor.View.Snapshot;
      Global_Registry.Items.Append (Rec);
      Global_Registry.Next_Id := Global_Registry.Next_Id + 1;
      Global_Registry.Active := Id;
      Global_Provisional_Active := False;
      Global_Provisional_Active_Id := No_Buffer;
      State.Active_Buffer_Token := Natural (Id);
   end Ensure_Global_Registry;

   function Global_Registry_Current_For
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return State.Registry_Token = Global_Owner_Token;
   end Global_Registry_Current_For;

   procedure Sync_Global_Active_From_State
     (State : Editor.State.State_Type)
   is
      I    : Natural;
      Copy : Buffer_State := State;
   begin
      if Global_Registry.Items.Is_Empty then
         return;
      end if;

      I := Index_Of (Global_Registry, Global_Registry.Active);
      if I = Natural'Last then
         return;
      end if;

      if Global_Owner_Token = 0 and then State.Registry_Token /= 0 then
         Global_Owner_Token := State.Registry_Token;
      end if;

      Copy.Active_Buffer_Token := Natural (Global_Registry.Active);
      Strip_Global_UI_State (Copy);
      Global_Registry.Items (I).State.all := Copy;
      Global_Registry.Items (I).Undo := Editor.History.Undo_Stack;
      Global_Registry.Items (I).Redo := Editor.History.Redo_Stack;
      Global_Registry.Items (I).View := Editor.View.Snapshot;
   end Sync_Global_Active_From_State;

   procedure Load_Global_Active_Into_State
     (State : in out Editor.State.State_Type)
   is
      I        : constant Natural := Index_Of (Global_Registry, Global_Registry.Active);
      Messages : constant Editor.Messages.Message_State := State.Messages;
      Feature_Panel : constant Editor.Feature_Panel.Feature_Panel_State := State.Feature_Panel;
      Outline : constant Editor.Outline.Outline_State := State.Outline;
      Feature_Messages : constant Editor.Feature_Messages.Message_Feature_State := State.Feature_Messages;
      Feature_Search_Results : constant Editor.Feature_Search_Results.Search_Results_Feature_State := State.Feature_Search_Results;
      Feature_Diagnostics : constant Editor.Feature_Diagnostics.Diagnostics_Feature_State := State.Feature_Diagnostics;
      Project  : constant Editor.Project.Project_State := State.Project;
      File_Tree : constant Editor.File_Tree.File_Tree_State := State.File_Tree;
      File_Tree_View : constant Editor.File_Tree_View.File_Tree_View_State := State.File_Tree_View;
      Panels   : constant Editor.Panels.Panel_Set := State.Panels;
      Active_Find_Input : constant Editor.Input_Field.Input_Field_State := State.Active_Find_Input;
      Active_Find_Prompt : constant Boolean := State.Active_Find_Prompt;
      Active_Find_Query  : constant Unbounded_String := State.Active_Find_Query;
      Active_Find_Case_Sensitive : constant Boolean := State.Active_Find_Case_Sensitive;
      Active_Find_Whole_Word : constant Boolean := State.Active_Find_Whole_Word;
      Active_Replace_Prompt : constant Boolean := State.Active_Replace_Prompt;
      Active_Replace_Text : constant Unbounded_String := State.Active_Replace_Text;
      Quick_Open : constant Editor.Quick_Open.Quick_Open_State := State.Quick_Open;
      Buffer_Switcher : constant Editor.Buffer_Switcher.Buffer_Switcher_State := State.Buffer_Switcher;
      Recent_Buffers : constant Editor.Recent_Buffers.Recent_Buffer_State := State.Recent_Buffers;
      Project_Search : constant Editor.Project_Search.Project_Search_State := State.Project_Search;
      Project_Search_Bar : constant Editor.Project_Search_Bar.Project_Search_Bar_State := State.Project_Search_Bar;
      Search_Results_View : constant Editor.Search_Results.Search_Results_View_State := State.Search_Results_View;
      Problems_View : constant Editor.Problems.Problems_View_State := State.Problems_View;
      Panel_Focus : constant Editor.Panel_Focus.Panel_Focus_State := State.Panel_Focus;
      Overlay_Focus : constant Editor.Overlay_Focus.Overlay_Focus_State := State.Overlay_Focus;
      Navigation_History : constant Editor.Navigation_History.Navigation_History_State := State.Navigation_History;
      Reopen_Candidate_Count : constant Natural := State.Reopen_Candidate_Count;
      Reopen_Candidate_Paths : constant Editor.State.Reopen_Candidate_Array := State.Reopen_Candidate_Paths;
      Reopen_Candidate_Labels : constant Editor.State.Reopen_Candidate_Array := State.Reopen_Candidate_Labels;
      Has_Reopen_Candidate : constant Boolean := State.Has_Reopen_Candidate;
      Reopen_Candidate_Path : constant Unbounded_String := State.Reopen_Candidate_Path;
      Reopen_Candidate_Label : constant Unbounded_String := State.Reopen_Candidate_Label;
      Dirty_Close_Prompt_Active : constant Boolean := State.Dirty_Close_Prompt_Active;
      Dirty_Close_Prompt_Scope : constant Editor.State.Dirty_Close_Scope :=
        State.Dirty_Close_Prompt_Scope;
      Dirty_Close_Prompt_All_Buffers : constant Boolean :=
        State.Dirty_Close_Prompt_All_Buffers;
      Dirty_Close_Prompt_Buffer : constant Natural := State.Dirty_Close_Prompt_Buffer;
      Dirty_Close_Prompt_Buffer_Count : constant Natural :=
        State.Dirty_Close_Prompt_Buffer_Count;
      Dirty_Close_Prompt_Buffer_Fingerprint : constant Natural :=
        State.Dirty_Close_Prompt_Buffer_Fingerprint;
      Dirty_Close_Prompt_Buffer_Ids : constant Unbounded_String :=
        State.Dirty_Close_Prompt_Buffer_Ids;
      Dirty_Close_Prompt_Dirty_Fingerprint : constant Natural :=
        State.Dirty_Close_Prompt_Dirty_Fingerprint;
      Dirty_Close_Prompt_Dirty_Buffer_Ids : constant Unbounded_String :=
        State.Dirty_Close_Prompt_Dirty_Buffer_Ids;
      Dirty_Close_Prompt_Dirty_Count : constant Natural :=
        State.Dirty_Close_Prompt_Dirty_Count;
      Dirty_Close_Prompt_File_Backed_Count : constant Natural :=
        State.Dirty_Close_Prompt_File_Backed_Count;
      Dirty_Close_Prompt_Untitled_Count : constant Natural :=
        State.Dirty_Close_Prompt_Untitled_Count;
      Dirty_Close_Prompt_Conflicted_Count : constant Natural :=
        State.Dirty_Close_Prompt_Conflicted_Count;
      Dirty_Close_Prompt_Unwritable_Count : constant Natural :=
        State.Dirty_Close_Prompt_Unwritable_Count;
      Dirty_Close_Prompt_Missing_Count : constant Natural :=
        State.Dirty_Close_Prompt_Missing_Count;
      Dirty_Close_Prompt_Save_Failure_Count : constant Natural :=
        State.Dirty_Close_Prompt_Save_Failure_Count;
      File_Target_Prompt_Active : constant Boolean :=
        State.File_Target_Prompt_Active;
      File_Target_Prompt_Command : constant Editor.Commands.Command_Id :=
        State.File_Target_Prompt_Command;
      File_Target_Prompt_Label : constant Unbounded_String :=
        State.File_Target_Prompt_Label;
      File_Target_Prompt_Input : constant Editor.Input_Field.Input_Field_State :=
        State.File_Target_Prompt_Input;
      Owner_Token : constant Natural := State.Registry_Token;
   begin
      if I = Natural'Last then
         return;
      end if;

      if Global_Owner_Token = 0 and then Owner_Token /= 0 then
         Global_Owner_Token := Owner_Token;
      end if;

      State := Global_Registry.Items (I).State.all;
      State.Registry_Token := Owner_Token;
      State.Active_Buffer_Token := Natural (Global_Registry.Active);
      State.Project := Project;
      State.File_Tree := File_Tree;
      State.File_Tree_View := File_Tree_View;
      State.Panels := Panels;
      State.Messages := Messages;
      State.Feature_Panel := Feature_Panel;
      State.Outline := Outline;
      State.Feature_Messages := Feature_Messages;
      State.Feature_Search_Results := Feature_Search_Results;
      State.Feature_Diagnostics := Feature_Diagnostics;
      State.Active_Find_Input := Active_Find_Input;
      State.Active_Find_Prompt := Active_Find_Prompt;
      State.Quick_Open := Quick_Open;
      State.Buffer_Switcher := Buffer_Switcher;
      State.Recent_Buffers := Recent_Buffers;
      State.Project_Search := Project_Search;
      State.Project_Search_Bar := Project_Search_Bar;
      State.Search_Results_View := Search_Results_View;
      State.Problems_View := Problems_View;
      State.Panel_Focus := Panel_Focus;
      State.Overlay_Focus := Overlay_Focus;
      State.Navigation_History := Navigation_History;
      State.Reopen_Candidate_Count := Reopen_Candidate_Count;
      State.Reopen_Candidate_Paths := Reopen_Candidate_Paths;
      State.Reopen_Candidate_Labels := Reopen_Candidate_Labels;
      State.Has_Reopen_Candidate := Has_Reopen_Candidate;
      State.Reopen_Candidate_Path := Reopen_Candidate_Path;
      State.Reopen_Candidate_Label := Reopen_Candidate_Label;
      State.Dirty_Close_Prompt_Active := Dirty_Close_Prompt_Active;
      State.Dirty_Close_Prompt_Scope := Dirty_Close_Prompt_Scope;
      State.Dirty_Close_Prompt_All_Buffers := Dirty_Close_Prompt_All_Buffers;
      State.Dirty_Close_Prompt_Buffer := Dirty_Close_Prompt_Buffer;
      State.Dirty_Close_Prompt_Buffer_Count := Dirty_Close_Prompt_Buffer_Count;
      State.Dirty_Close_Prompt_Buffer_Fingerprint :=
        Dirty_Close_Prompt_Buffer_Fingerprint;
      State.Dirty_Close_Prompt_Buffer_Ids := Dirty_Close_Prompt_Buffer_Ids;
      State.Dirty_Close_Prompt_Dirty_Fingerprint :=
        Dirty_Close_Prompt_Dirty_Fingerprint;
      State.Dirty_Close_Prompt_Dirty_Buffer_Ids :=
        Dirty_Close_Prompt_Dirty_Buffer_Ids;
      State.Dirty_Close_Prompt_Dirty_Count := Dirty_Close_Prompt_Dirty_Count;
      State.Dirty_Close_Prompt_File_Backed_Count :=
        Dirty_Close_Prompt_File_Backed_Count;
      State.Dirty_Close_Prompt_Untitled_Count := Dirty_Close_Prompt_Untitled_Count;
      State.Dirty_Close_Prompt_Conflicted_Count :=
        Dirty_Close_Prompt_Conflicted_Count;
      State.Dirty_Close_Prompt_Unwritable_Count :=
        Dirty_Close_Prompt_Unwritable_Count;
      State.Dirty_Close_Prompt_Missing_Count := Dirty_Close_Prompt_Missing_Count;
      State.Dirty_Close_Prompt_Save_Failure_Count :=
        Dirty_Close_Prompt_Save_Failure_Count;
      State.File_Target_Prompt_Active := File_Target_Prompt_Active;
      State.File_Target_Prompt_Command := File_Target_Prompt_Command;
      State.File_Target_Prompt_Label := File_Target_Prompt_Label;
      State.File_Target_Prompt_Input := File_Target_Prompt_Input;

      --  Active-buffer Find owns only canonical query/input state during
      --  buffer switches; no inactive Active Find prompt state is preserved.
      --  Replace is a transient overlay extension of Find, not buffer-local
      --  search state restored from the activated buffer snapshot.
      if State.Active_Find_Prompt then
         State.Active_Find_Query := Active_Find_Query;
         Editor.Input_Field.Set_Text
           (State.Active_Find_Input, To_String (State.Active_Find_Query));
         State.Active_Find_Matches.Clear;
         State.Active_Find_Match := Editor.Search.No_Match;
         State.Active_Find_Stale := Length (State.Active_Find_Query) > 0;
         State.Active_Find_Case_Sensitive := Active_Find_Case_Sensitive;
         State.Active_Find_Whole_Word := Active_Find_Whole_Word;
         State.Active_Find_Source_Buffer_Token := 0;
         State.Active_Replace_Prompt := Active_Replace_Prompt;
         if Active_Replace_Prompt then
            State.Active_Replace_Text := Active_Replace_Text;
         else
            State.Active_Replace_Text := Null_Unbounded_String;
         end if;
         State.Active_Replace_Error_Message := Null_Unbounded_String;
      else
         Editor.Input_Field.Clear (State.Active_Find_Input);
         State.Active_Find_Query := Null_Unbounded_String;
         State.Active_Find_Matches.Clear;
         State.Active_Find_Match := Editor.Search.No_Match;
         State.Active_Find_Stale := False;
         State.Active_Find_Source_Buffer_Token := 0;
         State.Active_Replace_Prompt := False;
         State.Active_Replace_Text := Null_Unbounded_String;
         State.Active_Replace_Error_Message := Null_Unbounded_String;
      end if;

      Editor.History.Undo_Stack := Global_Registry.Items (I).Undo;
      Editor.History.Redo_Stack := Global_Registry.Items (I).Redo;
      Editor.View.Restore (Global_Registry.Items (I).View, Snap_Visual_To_Target => True);
      Editor.State.Clear_Gutter_Marker_Hover (State);
      Editor.Render_Cache.Invalidate_All;
   end Load_Global_Active_Into_State;

   function Global_Count return Natural is
   begin
      return Count (Global_Registry);
   end Global_Count;

   function Global_Registry_For_UI return Buffer_Registry is
   begin
      return Global_Registry;
   end Global_Registry_For_UI;

   function Global_Summary_At
     (Index : Positive) return Buffer_Summary
   is
   begin
      return Summary_At (Global_Registry, Index);
   end Global_Summary_At;

   function Global_Summary_For
     (Id : Buffer_Id) return Buffer_Summary
   is
   begin
      return Summary_For (Global_Registry, Id);
   end Global_Summary_For;

   function Global_Metadata_For
     (Project     : Editor.Project.Project_State;
      Id          : Buffer_Id;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Metadata_Snapshot
   is
   begin
      return Metadata_For (Global_Registry, Project, Id, Selected_Id);
   end Global_Metadata_For;

   function Global_Audit_Buffers
     (Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Audit_Summary
   is
   begin
      return Audit_Buffers (Global_Registry, Project, Selected_Id);
   end Global_Audit_Buffers;

   function Global_Buffer_Metadata_Lifecycle_Audit_Coherent
     (Project     : Editor.Project.Project_State;
      Selected_Id : Buffer_Id := No_Buffer) return Boolean
   is
   begin
      return Buffer_Metadata_Lifecycle_Audit_Coherent
        (Global_Registry, Project, Selected_Id);
   end Global_Buffer_Metadata_Lifecycle_Audit_Coherent;

   function Global_Active_Buffer return Buffer_Id is
   begin
      if Global_Registry.Items.Is_Empty
        and then Global_Registry.Active = No_Buffer
        and then Global_Provisional_Active
      then
         return Global_Provisional_Active_Id;
      end if;

      return Active_Buffer (Global_Registry);
   end Global_Active_Buffer;

   function Global_Contains (Id : Buffer_Id) return Boolean is
   begin
      return Contains (Global_Registry, Id);
   end Global_Contains;

   function Global_Find_By_Path
     (Path  : String;
      Found : out Boolean) return Buffer_Id
   is
   begin
      return Find_By_Path (Global_Registry, Path, Found);
   end Global_Find_By_Path;

   function Global_File_Is_Dirty
     (Path : String) return Boolean
   is
      Found : Boolean := False;
      Id    : constant Buffer_Id := Global_Find_By_Path (Path, Found);
   begin
      return Found and then Is_Dirty (Global_Registry, Id);
   end Global_File_Is_Dirty;

   function Global_Next_Buffer return Buffer_Id is
   begin
      return Next_Buffer (Global_Registry);
   end Global_Next_Buffer;

   function Global_Previous_Buffer return Buffer_Id is
   begin
      return Previous_Buffer (Global_Registry);
   end Global_Previous_Buffer;

   function Global_Current_File return File_Identity is
   begin
      if Global_Registry.Items.Is_Empty then
         return (Has_Path => False,
                 Path => Null_Unbounded_String,
                 Display_Name => To_Unbounded_String ("Untitled"),
                 Dirty => False,
                 Baseline_Valid => False,
                 Saved_Generation => 0,
                 Last_Save_Failed => False,
                 Last_Reload_Failed => False,
                 Last_Revert_Failed => False,
                 Missing_Target_Surfaced => False,
                 Unreadable_Target_Surfaced => False,
                 Unwritable_Target_Surfaced => False,
                 External_Change_Surfaced => False,
                 Blocked_Close_Surfaced => False,
                 File_Token_Known => False,
                 File_Token_Label => Null_Unbounded_String);
      end if;
      return Current (Global_Registry).File_Info;
   end Global_Current_File;

   function Global_Display_Name
     (Id : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Global_Registry, Id);
   begin
      return Display_Name (Global_Registry, Id);
   end Global_Display_Name;

   function Global_Is_Buffer_Pinned (Id : Buffer_Id) return Boolean is
   begin
      return Is_Buffer_Pinned (Global_Registry, Id);
   end Global_Is_Buffer_Pinned;

   function Global_Has_Buffer_Label (Id : Buffer_Id) return Boolean is
   begin
      return Has_Buffer_Label (Global_Registry, Id);
   end Global_Has_Buffer_Label;

   function Global_Buffer_Label (Id : Buffer_Id) return String is
   begin
      return Buffer_Label (Global_Registry, Id);
   end Global_Buffer_Label;

   procedure Global_Set_Buffer_Label (Id : Buffer_Id; Label : String) is
   begin
      Set_Buffer_Label (Global_Registry, Id, Label);
   end Global_Set_Buffer_Label;

   procedure Global_Clear_Buffer_Label (Id : Buffer_Id) is
   begin
      Clear_Buffer_Label (Global_Registry, Id);
   end Global_Clear_Buffer_Label;

   function Global_Has_Buffer_Note (Id : Buffer_Id) return Boolean is
   begin
      return Has_Buffer_Note (Global_Registry, Id);
   end Global_Has_Buffer_Note;

   function Global_Buffer_Note (Id : Buffer_Id) return String is
   begin
      return Buffer_Note (Global_Registry, Id);
   end Global_Buffer_Note;

   procedure Global_Set_Buffer_Note (Id : Buffer_Id; Note : String) is
   begin
      Set_Buffer_Note (Global_Registry, Id, Note);
   end Global_Set_Buffer_Note;

   procedure Global_Clear_Buffer_Note (Id : Buffer_Id) is
   begin
      Clear_Buffer_Note (Global_Registry, Id);
   end Global_Clear_Buffer_Note;

   function Global_Has_Buffer_Group (Id : Buffer_Id) return Boolean is
   begin
      return Has_Buffer_Group (Global_Registry, Id);
   end Global_Has_Buffer_Group;

   function Global_Buffer_Group (Id : Buffer_Id) return String is
   begin
      return Buffer_Group (Global_Registry, Id);
   end Global_Buffer_Group;

   procedure Global_Assign_Buffer_Group (Id : Buffer_Id; Name : String) is
   begin
      Assign_Buffer_Group (Global_Registry, Id, Name);
   end Global_Assign_Buffer_Group;

   procedure Global_Clear_Buffer_Group (Id : Buffer_Id) is
   begin
      Clear_Buffer_Group (Global_Registry, Id);
   end Global_Clear_Buffer_Group;

   function Global_Has_Buffer_Groups return Boolean is
   begin
      return Has_Buffer_Groups (Global_Registry);
   end Global_Has_Buffer_Groups;

   function Global_Has_Active_Buffer_Group return Boolean is
   begin
      return Has_Active_Buffer_Group (Global_Registry);
   end Global_Has_Active_Buffer_Group;

   function Global_Active_Buffer_Group return String is
   begin
      return Active_Buffer_Group (Global_Registry);
   end Global_Active_Buffer_Group;

   function Global_First_Buffer_In_Group (Name : String) return Buffer_Id is
   begin
      return First_Buffer_In_Group (Global_Registry, Name);
   end Global_First_Buffer_In_Group;

   procedure Global_Set_Active_Buffer_Group (Name : String) is
   begin
      Set_Active_Buffer_Group (Global_Registry, Name);
   end Global_Set_Active_Buffer_Group;

   procedure Global_Clear_Active_Buffer_Group is
   begin
      Clear_Active_Buffer_Group (Global_Registry);
   end Global_Clear_Active_Buffer_Group;

   procedure Global_Cycle_Active_Buffer_Group (Forward : Boolean) is
   begin
      Cycle_Active_Buffer_Group (Global_Registry, Forward);
   end Global_Cycle_Active_Buffer_Group;

   function Global_Closeable_Unpinned_Clean_Outside_Active_Group_Count return Natural is
   begin
      return Closeable_Unpinned_Clean_Outside_Active_Group_Count (Global_Registry);
   end Global_Closeable_Unpinned_Clean_Outside_Active_Group_Count;

   procedure Global_Pin_Buffer (Id : Buffer_Id) is
   begin
      Pin_Buffer (Global_Registry, Id);
   end Global_Pin_Buffer;

   procedure Global_Unpin_Buffer (Id : Buffer_Id) is
   begin
      Unpin_Buffer (Global_Registry, Id);
   end Global_Unpin_Buffer;

   procedure Global_Toggle_Buffer_Pin (Id : Buffer_Id) is
   begin
      Toggle_Buffer_Pin (Global_Registry, Id);
   end Global_Toggle_Buffer_Pin;

   function Global_Unpinned_Clean_Buffer_Count return Natural is
   begin
      return Unpinned_Clean_Buffer_Count (Global_Registry);
   end Global_Unpinned_Clean_Buffer_Count;

   function Global_Dirty_Buffer_Count return Natural is
   begin
      return Dirty_Buffer_Count (Global_Registry);
   end Global_Dirty_Buffer_Count;

   function Global_Dirty_File_Backed_Buffer_Count return Natural is
   begin
      return Dirty_File_Backed_Buffer_Count (Global_Registry);
   end Global_Dirty_File_Backed_Buffer_Count;

   function Global_Dirty_Untitled_Buffer_Count return Natural is
   begin
      return Dirty_Untitled_Buffer_Count (Global_Registry);
   end Global_Dirty_Untitled_Buffer_Count;

   function Global_Clean_Buffer_Count return Natural is
   begin
      return Clean_Buffer_Count (Global_Registry);
   end Global_Clean_Buffer_Count;

   function Global_Dirty_Buffer_Summary
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return Dirty_Buffer_Summary (Global_Registry);
   end Global_Dirty_Buffer_Summary;

   function Global_Categorized_Dirty_Buffer_Summary
     (Project : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return Categorized_Dirty_Buffer_Summary (Global_Registry, Project);
   end Global_Categorized_Dirty_Buffer_Summary;

   function Global_Project_Lifecycle_Dirty_Buffer_Summary
     (Project : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return Project_Lifecycle_Dirty_Buffer_Summary (Global_Registry, Project);
   end Global_Project_Lifecycle_Dirty_Buffer_Summary;

   function Global_Project_Lifecycle_Buffer_Sets
     (Project : Editor.Project.Project_State) return Buffer_Project_Lifecycle_Sets
   is
   begin
      return Project_Lifecycle_Buffer_Sets (Global_Registry, Project);
   end Global_Project_Lifecycle_Buffer_Sets;

   function Global_Bookmark_Count return Natural
   is
      Total : Natural := 0;
   begin
      if Global_Registry.Items.Is_Empty then
         return 0;
      end if;

      for I in Global_Registry.Items.First_Index .. Global_Registry.Items.Last_Index loop
         if Global_Registry.Items (I).State /= null then
            Total := Total + Editor.Gutter_Markers.Bookmark_Count
              (Global_Registry.Items (I).State.Gutter_Markers);
         end if;
      end loop;

      return Total;
   end Global_Bookmark_Count;

   function Global_Has_Bookmarks return Boolean is
   begin
      return Global_Bookmark_Count > 0;
   end Global_Has_Bookmarks;

   procedure Global_Clear_All_Bookmarks
   is
   begin
      if Global_Registry.Items.Is_Empty then
         return;
      end if;

      for I in Global_Registry.Items.First_Index .. Global_Registry.Items.Last_Index loop
         if Global_Registry.Items (I).State /= null then
            Editor.Gutter_Markers.Clear_Bookmarks
              (Global_Registry.Items (I).State.Gutter_Markers);
         end if;
      end loop;
   end Global_Clear_All_Bookmarks;


   procedure Global_Prune_Stale_Bookmarks
   is
      Line_Count : Natural := 0;
   begin
      if Global_Registry.Items.Is_Empty then
         return;
      end if;

      for I in Global_Registry.Items.First_Index .. Global_Registry.Items.Last_Index loop
         if Global_Registry.Items (I).State /= null then
            Line_Count := Editor.State.Line_Count (Global_Registry.Items (I).State.all);
            Editor.Gutter_Markers.Prune_Bookmarks_At_Or_After
              (Global_Registry.Items (I).State.Gutter_Markers, Line_Count);
         end if;
      end loop;
   end Global_Prune_Stale_Bookmarks;

   procedure Global_Clear_All_Edit_History is
   begin
      if not Global_Registry.Items.Is_Empty then
         for I in Global_Registry.Items.First_Index .. Global_Registry.Items.Last_Index loop
            Global_Registry.Items (I).Undo.Clear;
            Global_Registry.Items (I).Redo.Clear;
         end loop;
      end if;

      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
   end Global_Clear_All_Edit_History;

   procedure Reset_Global_For_Test is
   begin
      Reset_Registry (Global_Registry);
      Global_Owner_Token := 0;
      Global_Provisional_Active := False;
      Global_Provisional_Active_Id := No_Buffer;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.View.Reset;
   end Reset_Global_For_Test;

   procedure Global_Add_File_Buffer
     (Path         : String;
      Display_Name : String;
      Contents     : String;
      New_Id       : out Buffer_Id)
   is
   begin
      New_Id := Add_Buffer_From_File
        (Global_Registry, Path, Display_Name, Contents);
      Global_Provisional_Active := False;
      Global_Provisional_Active_Id := No_Buffer;
   end Global_Add_File_Buffer;

   procedure Global_Add_Untitled_Buffer
     (New_Id : out Buffer_Id)
   is
   begin
      New_Id := Create_Untitled_Buffer (Global_Registry);
      Global_Provisional_Active := False;
      Global_Provisional_Active_Id := No_Buffer;
   end Global_Add_Untitled_Buffer;

   procedure Global_Set_Active_Buffer
     (Id : Buffer_Id)
   is
   begin
      Set_Active_Buffer (Global_Registry, Id);
   end Global_Set_Active_Buffer;

   procedure Global_Close_Buffer
     (Id     : Buffer_Id;
      Closed : out Boolean)
   is
   begin
      Close_Buffer (Global_Registry, Id, Closed);
      if Global_Registry.Items.Is_Empty then
         Global_Provisional_Active := False;
         Global_Provisional_Active_Id := No_Buffer;
      end if;
   end Global_Close_Buffer;

   procedure Global_Force_Close_Buffer
     (Id     : Buffer_Id;
      Closed : out Boolean)
   is
   begin
      Close_Buffer (Global_Registry, Id, Closed, Force => True);
      if Global_Registry.Items.Is_Empty then
         Global_Provisional_Active := False;
         Global_Provisional_Active_Id := No_Buffer;
      end if;
   end Global_Force_Close_Buffer;

   function Global_Has_Dirty_File_Under_Path
     (Path : String) return Boolean
   is
   begin
      if Global_Registry.Items.Is_Empty then
         return False;
      end if;

      for Item of Global_Registry.Items loop
         if Item.State /= null
           and then Item.State.File_Info.Has_Path
           and then Item.State.File_Info.Dirty
           and then Same_Or_Descendant_Path
             (To_String (Item.State.File_Info.Path), Path)
         then
            return True;
         end if;
      end loop;

      return False;
   end Global_Has_Dirty_File_Under_Path;

   function Global_Has_File_Under_Path
     (Path : String) return Boolean
   is
   begin
      if Global_Registry.Items.Is_Empty then
         return False;
      end if;

      for Item of Global_Registry.Items loop
         if Item.State /= null
           and then Item.State.File_Info.Has_Path
           and then Same_Or_Descendant_Path
             (To_String (Item.State.File_Info.Path), Path)
         then
            return True;
         end if;
      end loop;

      return False;
   end Global_Has_File_Under_Path;

   procedure Global_Rebase_Clean_File_Paths
     (Old_Root      : String;
      New_Root      : String;
      Rebased_Count : out Natural)
   is
      New_Path : Unbounded_String;
   begin
      Rebased_Count := 0;
      if Global_Registry.Items.Is_Empty then
         return;
      end if;

      for I in Global_Registry.Items.First_Index .. Global_Registry.Items.Last_Index loop
         if Global_Registry.Items (I).State /= null
           and then Global_Registry.Items (I).State.File_Info.Has_Path
           and then not Global_Registry.Items (I).State.File_Info.Dirty
           and then Same_Or_Descendant_Path
             (To_String (Global_Registry.Items (I).State.File_Info.Path), Old_Root)
         then
            New_Path := To_Unbounded_String
              (Rebase_Path
                 (To_String (Global_Registry.Items (I).State.File_Info.Path),
                  Old_Root,
                  New_Root));
            Global_Registry.Items (I).State.File_Info.Path := New_Path;
            Global_Registry.Items (I).State.File_Info.Display_Name :=
              To_Unbounded_String
                (Ada.Directories.Simple_Name (To_String (New_Path)));
            Rebased_Count := Rebased_Count + 1;
         end if;
      end loop;
   end Global_Rebase_Clean_File_Paths;

   procedure Global_Close_Clean_File_Paths_Under
     (Path         : String;
      Closed_Count : out Natural)
   is
      I      : Natural;
      Closed : Boolean;
   begin
      Closed_Count := 0;
      if Global_Registry.Items.Is_Empty then
         return;
      end if;

      I := Global_Registry.Items.First_Index;
      while not Global_Registry.Items.Is_Empty
        and then I <= Global_Registry.Items.Last_Index
      loop
         if Global_Registry.Items (I).State /= null
           and then Global_Registry.Items (I).State.File_Info.Has_Path
           and then not Global_Registry.Items (I).State.File_Info.Dirty
           and then Same_Or_Descendant_Path
             (To_String (Global_Registry.Items (I).State.File_Info.Path), Path)
         then
            declare
               Id_To_Close : constant Buffer_Id := Global_Registry.Items (I).Id;
            begin
               Close_Buffer (Global_Registry, Id_To_Close, Closed);
            end;
            if Closed then
               Closed_Count := Closed_Count + 1;
            else
               I := I + 1;
            end if;
         else
            I := I + 1;
         end if;
      end loop;
   end Global_Close_Clean_File_Paths_Under;

   procedure Global_Set_Blocked_Close_Surfaced
     (Id : Buffer_Id)
   is
      I : constant Natural := Index_Of (Global_Registry, Id);
   begin
      if I /= Natural'Last and then Global_Registry.Items (I).State /= null then
         Global_Registry.Items (I).State.File_Info.Blocked_Close_Surfaced := True;
      end if;
   end Global_Set_Blocked_Close_Surfaced;

   procedure Global_Clear_Clean_Reopen_Lifecycle
     (Id : Buffer_Id)
   is
      I : constant Natural := Index_Of (Global_Registry, Id);
   begin
      if I /= Natural'Last
        and then Global_Registry.Items (I).State /= null
        and then not Global_Registry.Items (I).State.File_Info.Dirty
      then
         Global_Registry.Items (I).State.File_Info.Last_Save_Failed := False;
         Global_Registry.Items (I).State.File_Info.Last_Reload_Failed := False;
         Global_Registry.Items (I).State.File_Info.Last_Revert_Failed := False;
         Global_Registry.Items (I).State.File_Info.Missing_Target_Surfaced := False;
         Global_Registry.Items (I).State.File_Info.Unreadable_Target_Surfaced := False;
         Global_Registry.Items (I).State.File_Info.Unwritable_Target_Surfaced := False;
         Global_Registry.Items (I).State.File_Info.External_Change_Surfaced := False;
         Global_Registry.Items (I).State.File_Info.Blocked_Close_Surfaced := False;
      end if;
   end Global_Clear_Clean_Reopen_Lifecycle;

end Editor.Buffers;
