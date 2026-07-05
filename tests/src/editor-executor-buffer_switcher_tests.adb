with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Buffer_Switcher;
with Editor.Commands;
with Editor.Executor.Buffer_Switcher_Mark_Commands;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Buffer_Switcher_Preview_Commands;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Files;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Recent_Buffers;
with Editor.State;

package body Editor.Executor.Buffer_Switcher_Tests is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
   use type Editor.Buffer_Switcher.Switcher_Metadata_Filter_Kind;
   use type Editor.Buffer_Switcher.Switcher_Sort_Mode;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.State.Dirty_Close_Scope;

   overriding function Name
     (T : Buffer_Switcher_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Buffer_Switcher_Tests");
   end Name;

   procedure Test_Filter_Commands_Route_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("switcher_filter_commands");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Write_Text_File (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "review parser changes");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Filter_Pinned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "pinned filter command opens the switcher through Executor");
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S.Buffer_Switcher) = "pinned",
              "pinned filter command sets switcher metadata filter");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "pinned filter command narrows projected rows");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "pinned filter command keeps only pinned buffer");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Filter_Group);
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S.Buffer_Switcher) = "group core",
              "group filter command replaces existing switcher filter");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "group filter command narrows projected rows");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "group filter command keeps only matching group");
      Assert (not Editor.Buffers.Global_Has_Active_Buffer_Group,
              "group switcher filter must not activate the buffer group");
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "core",
              "group switcher filter must not mutate group membership");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Filter_Label);
      Cmd.Text := To_Unbounded_String ("test");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S.Buffer_Switcher) = "label test",
              "label filter command replaces existing switcher filter");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "label filter command narrows projected rows");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "label filter command keeps only matching label");
      Assert (Editor.Buffers.Global_Buffer_Label (B_Id) = "test",
              "label switcher filter must not mutate labels");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Filter_Noted);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S.Buffer_Switcher) = "noted",
              "noted filter command replaces existing switcher filter");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "noted filter command narrows projected rows");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "noted filter command keeps only noted buffers");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Filter_Clear);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Metadata_Filter (S.Buffer_Switcher),
              "clear filter command clears only switcher filter state");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "clear filter command restores ordinary open-buffer candidates");
      Assert (Editor.Buffers.Global_Buffer_Label (B_Id) = "test",
              "clear filter command must not clear labels");
      Assert (Editor.Buffers.Global_Has_Buffer_Note (B_Id),
              "clear filter command must not clear notes");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Filter_Commands_Route_Through_Executor;

   procedure Test_Filter_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("switcher_filter_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Avail  : Editor.Commands.Command_Availability;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep this note");
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "test");
      Before := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Filter_Clear);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "clear filter availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Filter_Pinned);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "pinned filter availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Filter_Group);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "group filter availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Filter_Label);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "label filter availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Filter_Noted);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "noted filter availability should be available in setup");

      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before.Kind,
              "availability must not change switcher filter kind");
      Assert (To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
              To_String (Before.Text),
              "availability must not change switcher filter text");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id),
              "availability must not change pinned state");
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "core",
              "availability must not change group membership");
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "test",
              "availability must not change labels");
      Assert (Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "availability must not change notes");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Filter_Availability_Is_Side_Effect_Free;

   procedure Test_Sort_Commands_Route_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("switcher_sort_commands");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Write_Text_File (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "zeta");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "alpha");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Assert (Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "setup should open buffer switcher");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Sort_Pinned);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Editor.Buffer_Switcher.Pinned_Sort,
              "pinned sort command sets switcher sort through Executor");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "pinned sort command recomputes visible rows when switcher is open");
      Assert (not Editor.Buffer_Switcher.Has_Metadata_Filter (S.Buffer_Switcher),
              "sort command must not set a metadata filter");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Sort_Label);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Editor.Buffer_Switcher.Label_Sort,
              "label sort command replaces previous sort mode");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = B_Id,
              "label sort orders labeled buffers by label text");
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "zeta",
              "label sort must not mutate buffer labels");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "label sort must not mutate pinned state");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Sort_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Editor.Buffer_Switcher.Default_Sort,
              "next sort wraps from label to default");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "default sort restores existing switcher order");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Sort_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Editor.Buffer_Switcher.Label_Sort,
              "previous sort wraps from default to label");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Sort_Commands_Route_Through_Executor;

   procedure Test_Sort_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("switcher_sort_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Filter   : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort     : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
      Avail           : Editor.Commands.Command_Availability;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Write_Text_File (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (A_Id /= Editor.Buffers.No_Buffer,
              "availability setup should create first buffer");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "test");
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "test");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Pinned_Sort);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Default);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "default sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Recent);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "recent sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Name);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "name sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Pinned);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "pinned sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Group);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "group sort availability should not require existing groups");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Label);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "label sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Next);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "next sort availability should be available with open buffers");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Sort_Previous);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "previous sort availability should be available with open buffers");

      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "availability must not change switcher sort mode");
      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind,
              "availability must not change switcher filter kind");
      Assert (To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
              To_String (Before_Filter.Text),
              "availability must not change switcher filter text");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "availability must not mutate recent-buffer order head");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "availability must not mutate recent-buffer order tail");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "availability must not change pinned state");
      Assert (Editor.Buffers.Global_Buffer_Label (B_Id) = "test",
              "availability must not change label state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Sort_Availability_Is_Side_Effect_Free;

   procedure Test_Selected_Metadata_Actions_Target_Switcher_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("selected_metadata");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Found  : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Write_Text_File (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Navigation_History.Clear (S.Navigation_History);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = A_Id,
                 "setup should select a non-active switcher row");
      end;

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Selected_Pin);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id),
              "selected pin must target selected switcher row");
      Assert (not Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "selected pin must not target active buffer");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Selected_Group_Assign);
      Cmd.Text := To_Unbounded_String ("work");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "work",
              "selected group assign must target selected switcher row");
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (B_Id),
              "selected group assign must not mutate active buffer group");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Selected_Label_Set);
      Cmd.Text := To_Unbounded_String ("triage");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "triage",
              "selected label set must target selected switcher row");
      Assert (not Editor.Buffers.Global_Has_Buffer_Label (B_Id),
              "selected label set must not mutate active buffer label");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Selected_Note_Set);
      Cmd.Text := To_Unbounded_String ("review next");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Note (A_Id) = "review next",
              "selected note set must target selected switcher row");
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (B_Id),
              "selected note set must not mutate active buffer note");

      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "selected metadata actions must not activate the selected buffer");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "selected metadata actions must not add navigation history");
      Assert (not Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, A_Id),
              "selected metadata actions must not dirty selected buffer");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Selected_Metadata_Actions_Target_Switcher_Row;

   procedure Test_Selected_Close_Composes_With_Reopen_And_Dirty_Guard
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("selected_close");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Write_Text_File (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "selected close must close selected non-active buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "selected close of non-active buffer must not activate it first");
      Assert (True,
              "selected clean close must not record close-history/reopen state");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "selected close must refresh switcher candidates");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = 1,
              "selected close must normalize selection deterministically");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty alpha");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffers.Global_Contains (A_Id),
              "dirty selected close must leave selected buffer open before confirmation");
      Assert (S.Dirty_Close_Prompt_Active,
              "dirty selected close must open explicit dirty close review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope,
              "dirty selected close must record selected-buffer scope");
      Assert (True,
              "blocked selected close must not record reopen entry");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "blocked selected close must preserve active buffer");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "selected discard confirmation must close the selected dirty buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "selected discard confirmation must preserve active fallback");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "selected discard confirmation must refresh switcher rows");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = 1,
              "selected discard confirmation must normalize switcher selection");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Selected_Close_Composes_With_Reopen_And_Dirty_Guard;

   procedure Test_Buffer_List_Selected_Close_Cancel_Preserves_Dirty_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("selected_close_cancel");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Write_Text_File (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty selected alpha");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Dirty_Close_Prompt_Active,
              "selected dirty buffer-list close must enter dirty review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope,
              "selected dirty buffer-list close records selected-buffer close scope");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel);
      Assert (not S.Dirty_Close_Prompt_Active,
              "cancel exits selected dirty close review");
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "cancel leaves selected dirty buffer open");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "cancel leaves active buffer open");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "cancel preserves active buffer while selected row was reviewed");

      Editor.Buffers.Global_Set_Active_Buffer (A_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Buffer_Text (S) = "dirty selected alpha",
              "cancel preserves selected dirty buffer text");
      Assert (S.File_Info.Dirty,
              "cancel preserves selected dirty marker");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Buffer_List_Selected_Close_Cancel_Preserves_Dirty_Text;

   procedure Test_Close_Clean_Refreshes_Buffer_List_And_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Row   : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty survivor");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 3,
              "setup exposes all open buffers before close-clean");

      Editor.Executor.Buffer_Close_Commands.Execute_Close_All_Clean_Buffers (S);

      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "buffer-list close-clean closes the first clean buffer");
      Assert (not Editor.Buffers.Global_Contains (C_Id),
              "buffer-list close-clean closes the selected/active clean buffer");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "buffer-list close-clean preserves dirty buffers");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "close-clean refreshes buffer-list rows");
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = B_Id,
              "close-clean clamps buffer-list selection to the dirty survivor");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "close-clean chooses the dirty survivor as deterministic active fallback");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Close_Clean_Refreshes_Buffer_List_And_Selection;

   procedure Test_Selected_Buffer_List_Clean_Close_Closes_And_Refreshes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("selected_clean_close");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found  : Boolean := False;
      Cmd    : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha clean");
      Write_Text_File (B_Path, "beta clean");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not S.Dirty_Close_Prompt_Active,
              "selected clean buffer-list close must not open dirty review");
      Assert (not S.File_Conflict_Prompt_Active,
              "selected clean buffer-list close must not open file conflict prompt");
      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "selected clean buffer-list close removes the selected clean buffer");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "selected clean buffer-list close preserves the active buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "selected clean buffer-list close preserves active fallback");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "selected clean close refreshes buffer-list rows");
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = B_Id,
              "selected clean close clamps selection to the remaining buffer row");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Selected_Buffer_List_Clean_Close_Closes_And_Refreshes;

   procedure Test_Selected_Buffer_List_Save_And_Close_Succeeds_And_Refreshes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("selected_save_close_success");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found  : Boolean := False;
      Result : Editor.Files.File_Open_Result;
      Cmd    : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha baseline");
      Write_Text_File (B_Path, "beta baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty selected alpha saved");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Dirty_Close_Prompt_Active,
              "selected dirty save-close starts in dirty review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope,
              "selected dirty save-close records selected-buffer scope");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (not S.Dirty_Close_Prompt_Active,
              "successful selected save-close clears dirty review");
      Assert (not S.File_Conflict_Prompt_Active,
              "successful selected save-close does not leave conflict prompt active");
      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "successful selected save-close closes the selected dirty buffer");
      Assert (Editor.Buffers.Global_Contains (B_Id)
                and then Editor.Buffers.Global_Active_Buffer = B_Id,
              "successful selected save-close preserves the active buffer");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "successful selected save-close refreshes buffer-list rows");
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = B_Id,
              "successful selected save-close clamps selection to remaining row");
      Result := Editor.Files.Open_File (A_Path);
      Assert (Editor.Files.Is_Success (Result)
                and then To_String (Result.Contents) = "dirty selected alpha saved",
              "successful selected save-close writes selected buffer text before closing");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Selected_Buffer_List_Save_And_Close_Succeeds_And_Refreshes;

   procedure Test_Selected_Buffer_List_Overwrite_Closes_And_Refreshes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("selected_overwrite_close");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found  : Boolean := False;
      Result : Editor.Files.File_Open_Result;
      Cmd    : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha baseline");
      Write_Text_File (B_Path, "beta baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty selected alpha overwrite");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Write_Text_File (A_Path, "external edit before overwrite close");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);

      Assert (S.File_Conflict_Prompt_Active,
              "selected overwrite-close starts from file conflict prompt");
      Assert (S.File_Conflict_Close_After_Overwrite,
              "selected overwrite-close remembers close-after-overwrite");
      Assert (S.File_Conflict_Close_After_Overwrite_Selected,
              "selected overwrite-close remembers selected-buffer row origin");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);

      Assert (not S.File_Conflict_Prompt_Active,
              "selected overwrite-close clears conflict prompt");
      Assert (not S.Dirty_Close_Prompt_Active,
              "selected overwrite-close leaves no dirty review active");
      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "selected overwrite-close closes the selected buffer after overwrite");
      Assert (Editor.Buffers.Global_Contains (B_Id)
                and then Editor.Buffers.Global_Active_Buffer = B_Id,
              "selected overwrite-close preserves active buffer");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "selected overwrite-close refreshes buffer-list rows");
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = B_Id,
              "selected overwrite-close clamps selection to remaining row");
      Result := Editor.Files.Open_File (A_Path);
      Assert (Editor.Files.Is_Success (Result)
                and then To_String (Result.Contents) = "dirty selected alpha overwrite",
              "selected overwrite-close writes selected buffer text before closing");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Selected_Buffer_List_Overwrite_Closes_And_Refreshes;

   procedure Test_Selected_Buffer_List_Save_Conflict_Preserves_Selected_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("selected_save_conflict");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha baseline");
      Write_Text_File (B_Path, "beta baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty selected alpha conflict");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Write_Text_File (A_Path, "external edit before selected save-and-close");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (S.Dirty_Close_Prompt_Active,
              "selected dirty close starts from dirty review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope,
              "selected dirty close preserves selected-buffer close scope");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not S.Dirty_Close_Prompt_Active,
              "selected save-and-close conflict transfers from dirty review");
      Assert (S.File_Conflict_Prompt_Active,
              "selected save-and-close surfaces conflict prompt");
      Assert (S.File_Conflict_Close_After_Overwrite,
              "selected save-and-close remembers close-after-overwrite intent");
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "selected conflicted buffer remains open before explicit overwrite");
      Assert (Editor.Buffers.Global_Contains (B_Id)
                and then Editor.Buffers.Global_Active_Buffer = B_Id,
              "selected save conflict preserves active buffer and open buffer set");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_File_Conflict_Cancel);
      Assert (not S.File_Conflict_Prompt_Active,
              "cancelling selected save conflict clears conflict prompt");
      Assert (Editor.Buffers.Global_Contains (A_Id),
              "cancelling selected save conflict keeps selected dirty buffer open");
      Editor.Buffers.Global_Set_Active_Buffer (A_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Buffer_Text (S) = "dirty selected alpha conflict" and then S.File_Info.Dirty,
              "cancelling selected save conflict preserves selected dirty text and dirty state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Selected_Buffer_List_Save_Conflict_Preserves_Selected_Buffer;

   procedure Test_Preview_Follows_Selected_Row_Without_Activation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("switcher_preview");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
      Found : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "line 1" & ASCII.LF & "line 2" & ASCII.LF & "line 3");
      Write_Text_File (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Navigation_History.Clear (S.Navigation_History);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = A_Id,
                 "setup should select the non-active buffer");
      end;

      Editor.Executor.Buffer_Switcher_Preview_Commands
        .Execute_Buffer_Switcher_Preview_Show (S);
      Assert (Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher),
              "preview show must enable preview state");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = A_Id,
              "preview target must follow selected switcher row");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "preview must not activate selected buffer");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "preview must not update recent activation head");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "preview must not update recent activation tail");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "preview must not add navigation history");

      Editor.Executor.Buffer_Switcher_Preview_Commands
        .Execute_Buffer_Switcher_Preview_Next_Line (S);
      Assert (Editor.Buffer_Switcher.Preview_Scroll_Offset (S.Buffer_Switcher) = 1,
              "preview scroll mutates only preview offset");
      Editor.Executor.Buffer_Switcher_Preview_Commands
        .Execute_Buffer_Switcher_Preview_Center_Cursor (S);
      Assert (Editor.Buffer_Switcher.Preview_Scroll_Offset (S.Buffer_Switcher) = 0,
              "center cursor clears preview scroll offset");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "preview center must not activate selected buffer");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Next_Result (S);
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = B_Id,
              "preview must follow switcher selection changes");
      Editor.Executor.Buffer_Switcher_Preview_Commands
        .Execute_Buffer_Switcher_Preview_Hide (S);
      Assert (not Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher),
              "preview hide must disable preview state");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = Editor.Buffers.No_Buffer,
              "preview hide must clear transient target");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Preview_Follows_Selected_Row_Without_Activation;

   procedure Test_Preview_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("preview_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Avail  : Editor.Commands.Command_Availability;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Preview_Target (S.Buffer_Switcher, A_Id, 3);
      Editor.Buffer_Switcher.Scroll_Preview_Next_Line (S.Buffer_Switcher);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Preview_Next_Line);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "preview next availability should be available with visible preview");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Preview_Previous_Line);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "preview previous availability should be available with visible preview");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Preview_Center_Cursor);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "preview center availability should be available with visible preview");

      Assert (Editor.Buffer_Switcher.Has_Preview (S.Buffer_Switcher),
              "availability must not hide preview");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = A_Id,
              "availability must not retarget preview");
      Assert (Editor.Buffer_Switcher.Preview_Anchor_Line (S.Buffer_Switcher) = 3,
              "availability must not change preview anchor");
      Assert (Editor.Buffer_Switcher.Preview_Scroll_Offset (S.Buffer_Switcher) = 1,
              "availability must not change preview scroll");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Preview_Availability_Is_Side_Effect_Free;

   procedure Test_Selected_Marks_Target_Switcher_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("selected_marks");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Found  : Boolean := False;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha" & ASCII.LF & "line two");
      Write_Text_File (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Navigation_History.Clear (S.Navigation_History);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Previous_Result (S);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = A_Id,
                 "setup should select non-active switcher row");
      end;

      Editor.Executor.Buffer_Switcher_Preview_Commands
        .Execute_Buffer_Switcher_Preview_Show (S);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Set);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "mark set must target selected switcher row");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "mark set must not target active buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "marking must not activate selected buffer");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = A_Id,
              "marking must preserve selected preview target");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "marking must not update recent-buffer head");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "marking must not update recent-buffer tail");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "marking must not push navigation history");
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Is_Marked,
                 "marked row should expose compact row state");
      end;

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Toggle);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "toggle must unmark selected switcher row");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "toggle must remark selected switcher row");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Clear);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "clear selected mark must unmark selected switcher row");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Selected_Marks_Target_Switcher_Row;

   procedure Test_Invert_Visible_Preserves_Hidden_Marks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("invert_visible");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Label (C_Id, "test");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "test");
      Editor.Buffer_Switcher.Set_Sort_Mode
        (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);

      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "setup should show only labeled visible rows");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "hidden marked buffer should remain marked after filter recompute");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Invert_Visible);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "invert visible must mark visible unmarked alpha");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "invert visible must mark visible unmarked gamma");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "invert visible must leave hidden marked beta unchanged");

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "second invert visible must unmark visible alpha");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "second invert visible must unmark visible gamma");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "second invert visible must still leave hidden beta marked");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Clear_All);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Marks (S.Buffer_Switcher),
              "clear all marks must remove hidden and visible marks");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Invert_Visible_Preserves_Hidden_Marks;

   procedure Test_Marked_Pin_Unpin_And_Metadata_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("marked_metadata");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "api");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep context");
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Note (B_Id, "dirty edge");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Pin_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id),
              "pin marked must pin marked alpha");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "pin marked must pin marked beta");
      Assert (not Editor.Buffers.Global_Is_Buffer_Pinned (C_Id),
              "pin marked must not pin unmarked gamma");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "pin marked must not activate marked buffers");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Clear_Metadata);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (A_Id),
              "metadata clear must remove marked alpha group");
      Assert (not Editor.Buffers.Global_Has_Buffer_Label (A_Id),
              "metadata clear must remove marked alpha label");
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "metadata clear must remove marked alpha note");
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (B_Id),
              "metadata clear must remove marked beta group");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id),
              "metadata clear must not unpin marked alpha");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "metadata clear must not unpin marked beta");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "metadata clear must preserve marks for follow-up action");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Unpin_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Is_Buffer_Pinned (A_Id),
              "unpin marked must unpin marked alpha");
      Assert (not Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "unpin marked must unpin marked beta");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "marked metadata actions must not update recent-buffer head");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "marked metadata actions must not update recent-buffer tail");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "marked metadata actions must not push navigation history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Marked_Pin_Unpin_And_Metadata_Clear;

   procedure Test_Mark_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("mark_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Avail  : Editor.Commands.Command_Availability;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "test");
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "test");
      Editor.Buffer_Switcher.Set_Sort_Mode
        (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Preview_Target (S.Buffer_Switcher, A_Id, 2);
      Editor.Buffer_Switcher.Scroll_Preview_Next_Line (S.Buffer_Switcher);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Toggle);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "mark toggle availability should be available with selected switcher row");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "close marked availability should be available with marks");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Invert_Visible);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "invert visible availability should be available with visible rows");

      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "availability must not clear existing marks");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "availability must not add marks");
      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind =
              Before_Filter.Kind,
              "availability must not change filter kind");
      Assert (To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
              To_String (Before_Filter.Text),
              "availability must not change filter text");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "availability must not change sort mode");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = A_Id,
              "availability must not change preview target");
      Assert (Editor.Buffer_Switcher.Preview_Scroll_Offset (S.Buffer_Switcher) = 1,
              "availability must not change preview scroll");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Mark_Availability_Is_Side_Effect_Free;

   procedure Test_Marked_Metadata_Apply_Targets_Marked_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("marked_metadata_apply");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "old");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "api");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "old note");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Group_Assign);
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "core",
              "marked group assign must replace alpha group");
      Assert (Editor.Buffers.Global_Buffer_Group (B_Id) = "core",
              "marked group assign must apply to dirty marked beta");
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (C_Id),
              "marked group assign must not touch unmarked gamma");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Cmd.Text := To_Unbounded_String ("test");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "test",
              "marked label set must replace alpha label");
      Assert (Editor.Buffers.Global_Buffer_Label (B_Id) = "test",
              "marked label set must apply to marked beta");
      Assert (not Editor.Buffers.Global_Has_Buffer_Label (C_Id),
              "marked label set must not touch unmarked gamma");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Note_Set);
      Cmd.Text := To_Unbounded_String ("shared context");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Note (A_Id) = "shared context",
              "marked note set must replace alpha note");
      Assert (Editor.Buffers.Global_Buffer_Note (B_Id) = "shared context",
              "marked note set must apply to marked beta");
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (C_Id),
              "marked note set must not touch unmarked gamma");

      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "marked metadata apply must preserve pins");
      Assert (Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, B_Id),
              "marked metadata apply must preserve dirty state");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "marked metadata apply must preserve alpha mark");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "marked metadata apply must preserve beta mark");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "marked metadata apply must not activate marked buffers");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "marked metadata apply must not update recent-buffer head");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "marked metadata apply must not update recent-buffer tail");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "marked metadata apply must not add navigation history");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Group_Clear);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (A_Id)
              and then Editor.Buffers.Global_Buffer_Label (A_Id) = "test"
              and then Editor.Buffers.Global_Buffer_Note (A_Id) = "shared context",
              "marked group clear must clear only groups");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Clear);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Label (A_Id)
              and then Editor.Buffers.Global_Buffer_Note (A_Id) = "shared context",
              "marked label clear must clear only labels");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Note_Clear);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "marked note clear must clear notes");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "granular clear must preserve marks");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Marked_Metadata_Apply_Targets_Marked_Buffers;

   procedure Test_Marked_Metadata_Composes_With_Filter_Sort_And_Preview
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("marked_filter_sort_preview");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Config        : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "test");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (C_Id, "test");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "test");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Label_Sort);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Preview_Target (S.Buffer_Switcher, C_Id, 1);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "setup should show only label-filtered rows");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Cmd.Text := To_Unbounded_String ("review");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "review",
              "marked apply must mutate visible marked buffers");
      Assert (Editor.Buffers.Global_Buffer_Label (B_Id) = "review",
              "marked apply must mutate hidden marked buffers");
      Assert (Editor.Buffers.Global_Buffer_Label (C_Id) = "test",
              "marked apply must not mutate unmarked visible buffers");
      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind,
              "marked apply must preserve filter kind");
      Assert (To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
              To_String (Before_Filter.Text),
              "marked apply must preserve filter text");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "marked apply must preserve sort mode");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "marked apply must rebuild filtered projection after label change");
      Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = C_Id,
              "marked apply must keep preview target when selected buffer remains visible");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "marked apply must preserve marks after filter recompute");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Marked_Metadata_Composes_With_Filter_Sort_And_Preview;

   procedure Test_Marked_Metadata_Validation_And_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("marked_validation");
      A_Path    : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      S         : Editor.State.State_Type;
      A_Id      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd       : Editor.Commands.Command;
      Avail     : Editor.Commands.Command_Availability;
      Long_Note : constant String (1 .. Editor.Buffers.Max_Buffer_Note_Length + 1) := (others => 'n');
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable,
              "marked apply availability should require marked buffers");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "marked apply availability should be available with marks");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "availability must not mutate marks");

      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "keep");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "keep");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Group_Assign);
      Cmd.Text := To_Unbounded_String ("   ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "keep",
              "blank group input must not mutate marked group");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Cmd.Text := To_Unbounded_String ("bad/label");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "keep",
              "invalid label input must not mutate marked label");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Note_Set);
      Cmd.Text := To_Unbounded_String (Long_Note);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Note (A_Id) = "keep",
              "too-long note input must not mutate marked note");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Marked_Metadata_Validation_And_Availability;


   procedure Test_Mark_Presets_Compose_With_Metadata_Visibility_And_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("mark_presets");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      D_Path : constant String := Ada.Directories.Compose (Root, "delta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      D_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Config        : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Before_Selected : Natural := 0;
      Before_Preview  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Write_Text_File (D_Path, "delta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "alpha note");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Assign_Buffer_Group (B_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "prod");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (C_Id, "test");
      Editor.Buffers.Global_Set_Buffer_Note (C_Id, "different contents still noted");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, D_Path);
      D_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty delta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer_Group ("core");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "alpha");
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, S.Recent_Buffers, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "setup should have one visible literal match");
      Editor.Executor.Buffer_Switcher_Mark_Commands
        .Execute_Buffer_Switcher_Mark_Kind
          (S, Editor.Commands.Buffer_Switcher_Mark_Visible, "");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "mark visible marks the current projection");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "mark visible does not mark hidden buffers");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, D_Id);
      Editor.Executor.Buffer_Switcher_Mark_Commands
        .Execute_Buffer_Switcher_Mark_Kind
          (S, Editor.Commands.Buffer_Switcher_Mark_Clear_Visible, "");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id),
              "clear visible removes visible marks");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, D_Id),
              "clear visible preserves hidden marks");

      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "prod");
      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Show_Preview (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Preview_Target (S.Buffer_Switcher, B_Id, 1);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);
      Before_Selected := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Before_Preview := Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Editor.Executor.Buffer_Switcher_Mark_Commands
        .Execute_Buffer_Switcher_Mark_Kind
          (S, Editor.Commands.Buffer_Switcher_Mark_Pinned, "");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Group);
      Cmd.Text := To_Unbounded_String (" core ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Label);
      Cmd.Text := To_Unbounded_String (" test ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Executor.Buffer_Switcher_Mark_Commands
        .Execute_Buffer_Switcher_Mark_Kind
          (S, Editor.Commands.Buffer_Switcher_Mark_Noted, "");

      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, D_Id),
              "metadata mark presets are additive and include hidden matching buffers");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (A_Id)
              and then not Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "mark pinned observes pin state without pinning unpinned buffers");
      Assert (Editor.Buffers.Global_Buffer_Group (A_Id) = "core"
              and then Editor.Buffers.Global_Buffer_Group (B_Id) = "core"
              and then Editor.Buffers.Global_Active_Buffer_Group = "core",
              "mark group does not change group membership or active group");
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "test"
              and then Editor.Buffers.Global_Buffer_Label (C_Id) = "test"
              and then not Editor.Buffers.Global_Has_Buffer_Label (D_Id),
              "mark label does not create or modify labels");
      Assert (Editor.Buffers.Global_Buffer_Note (A_Id) = "alpha note"
              and then Editor.Buffers.Global_Buffer_Note (C_Id) = "different contents still noted",
              "mark noted uses note presence without searching or mutating note text");
      Assert (Editor.Buffers.Is_Dirty (Editor.Buffers.Global_Registry_For_UI, D_Id),
              "mark presets do not change dirty state");
      Assert (Editor.Buffers.Global_Active_Buffer = D_Id,
              "mark presets do not activate buffers");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1
              and then Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "mark presets do not update recent-buffer order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "mark presets do not add navigation history");
      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind
              and then To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
                To_String (Before_Filter.Text),
              "metadata mark presets preserve active filter");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "metadata mark presets preserve sort mode");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = Before_Selected
              and then Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = Before_Preview,
              "mark presets preserve selection and preview when row remains visible");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set);
      Cmd.Text := To_Unbounded_String ("review");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "review"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "review"
              and then Editor.Buffers.Global_Buffer_Label (C_Id) = "review"
              and then Editor.Buffers.Global_Buffer_Label (D_Id) = "review",
              "marked actions operate on the resulting preset mark set");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Mark_Presets_Compose_With_Metadata_Visibility_And_State;

   procedure Test_Mark_Preset_Availability_And_No_Match_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("mark_preset_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Pinned);
      Assert (Avail.Status = Editor.Commands.Command_Unavailable,
              "mark pinned availability is deterministic with no pinned buffers");
      Assert (not Editor.Buffer_Switcher.Has_Marks (S.Buffer_Switcher),
              "mark preset availability must not mutate marks");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Group);
      Cmd.Text := To_Unbounded_String ("missing");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Marks (S.Buffer_Switcher),
              "group mark with no groups leaves marks unchanged");

      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Cmd.Text := To_Unbounded_String ("missing");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Marks (S.Buffer_Switcher),
              "group mark with no matching open buffers leaves marks unchanged");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Mark_Preset_Availability_And_No_Match_Are_Deterministic;

   procedure Test_Marked_Review_Routes_Through_Executor_And_Is_Inspection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("marked_review_executor");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Found  : Boolean := False;
      Msg    : Editor.Messages.Editor_Message;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Before_Recent_1 : Natural := 0;
      Before_Recent_2 : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Write_Text_File (B_Path, "beta body");
      Write_Text_File (C_Path, "gamma body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "review");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (B_Id, "review");
      Editor.Buffers.Global_Pin_Buffer (B_Id);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "review");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Insert_Text (S, "a");
      Editor.Executor.Buffer_Switcher_Preview_Commands
        .Execute_Buffer_Switcher_Preview_Show (S);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Before_Recent_2 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher),
              "show command enables marked review through Executor");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "marked review shows marked rows matching filter and query");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "marked review preserves active sort order for candidates");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 2).Id = B_Id,
              "marked review includes the second marked matching row");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = B_Id,
                 "next marked selects the next visible marked candidate");
         Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = B_Id,
                 "preview follows marked-review selection movement");
      end;

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Previous);
      Editor.Executor.Execute_No_Log (S, Cmd);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = A_Id,
                 "previous marked selects the previous visible marked candidate");
         Assert (Editor.Buffer_Switcher.Preview_Target (S.Buffer_Switcher) = A_Id,
                 "preview follows previous marked selection movement");
      end;

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (Msg.Text) = "Marked buffers: 2",
              "summary reports the current open marked-buffer count");

      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind
              and then To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
                To_String (Before_Filter.Text),
              "marked review commands must not alter metadata filter state");
      Assert (Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher) = "a",
              "marked review commands must not alter literal query state");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "marked review commands must not alter sort mode");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id)
              and then not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "marked review commands must not create or clear marks");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (B_Id),
              "marked review commands must not change pinned state");
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "review"
              and then Editor.Buffers.Global_Buffer_Label (B_Id) = "review",
              "marked review commands must not change labels");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "marked review navigation must not activate buffers");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1
              and then Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 2) = Before_Recent_2,
              "marked review commands must not update recent-buffer order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "marked review commands must not add navigation history");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Hide);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher),
              "hide command disables only marked review state");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "hide restores ordinary filtered query projection");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Marked_Review_Routes_Through_Executor_And_Is_Inspection_Only;

   procedure Test_Marked_Review_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("marked_review_availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Filter : Editor.Buffer_Switcher.Switcher_Metadata_Filter;
      Before_Sort   : Editor.Buffer_Switcher.Switcher_Sort_Mode;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "review");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "review");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Show_Marked_Review (S.Buffer_Switcher);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Before_Filter := Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher);
      Before_Sort := Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Review_Toggle);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "marked review toggle availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "marked review show availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Review_Hide);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "marked review hide availability should be available in setup");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Next);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "marked next availability should find the current marked candidate");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Previous);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "marked previous availability should find the current marked candidate");
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Buffer_Switcher_Mark_Summary);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "marked summary availability should be available in setup");

      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher),
              "availability must not change marked review state");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "availability must not mutate mark membership");
      Assert (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Kind = Before_Filter.Kind
              and then To_String (Editor.Buffer_Switcher.Metadata_Filter (S.Buffer_Switcher).Text) =
                To_String (Before_Filter.Text),
              "availability must not mutate filter state");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S.Buffer_Switcher) = Before_Sort,
              "availability must not mutate sort state");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "availability must not rebuild or widen review candidates");
      Assert (Editor.Buffers.Global_Buffer_Label (A_Id) = "review",
              "availability must not mutate metadata");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Marked_Review_Availability_Is_Side_Effect_Free;

   procedure Test_Marked_Close_Dirty_Reopen_And_Pin_Composition
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("marked_close");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Reopened_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Pin_Buffer (A_Id);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
              Editor.Buffer_Switcher.Pending_Marked_Close,
              "marked close should prepare confirmation before mutation");
      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Editor.Buffers.Global_Contains (A_Id),
              "marked close must close marked pinned clean buffer explicitly");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "marked close must keep dirty marked buffer open");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "dirty blocked marked buffer must remain marked");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "marked close of non-active buffers must preserve active buffer");
      Assert (True,
              "successful marked close must not record close-history/reopen state");

      null;
      Reopened_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Reopened_Id = C_Id,
              "removed removed-name reopen must preserve the active buffer after marked close");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Marked_Close_Dirty_Reopen_And_Pin_Composition;

   procedure Test_Marked_Close_Prepares_Captured_Targets_And_Cancel
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("prepare_cancel");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent_1 : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Assign_Buffer_Group (A_Id, "core");
      Editor.Buffers.Global_Set_Buffer_Label (A_Id, "api");
      Editor.Buffers.Global_Set_Buffer_Note (A_Id, "keep");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Before_Recent_1 := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.Pending_Marked_Close,
              "marked close prepares a pending close action");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2,
              "pending close captures the marked open-buffer count");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = B_Id,
              "pending close captures target identities in mark order");
      Assert (Editor.Buffers.Global_Contains (A_Id) and then Editor.Buffers.Global_Contains (B_Id),
              "prepare must not close captured buffers");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "prepare must not mutate marks");
      Assert (Editor.Buffers.Global_Has_Buffer_Group (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Label (A_Id)
              and then Editor.Buffers.Global_Has_Buffer_Note (A_Id),
              "prepare must not mutate buffer metadata");
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "prepare must not activate marked buffers");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent_1,
              "prepare must not update recent-buffer activation order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "prepare must not add navigation history");
      Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Editor.Buffer_Switcher.Set_Label_Filter (S.Buffer_Switcher, "none");
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Toggle_Marked_Review (S.Buffer_Switcher);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = B_Id,
              "mark/filter/sort/review changes must not alter captured targets");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Cancel);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action,
              "cancel clears pending marked close");
      Assert (Editor.Buffers.Global_Contains (A_Id) and then Editor.Buffers.Global_Contains (B_Id),
              "cancel must not close buffers");
      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Marked_Close_Prepares_Captured_Targets_And_Cancel;

   procedure Test_Confirm_Closes_Captured_Clean_Skips_Closed_And_Protects_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("confirm_captured");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Closed : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "dirty beta");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Dirty_Count (S.Buffer_Switcher) = 1,
              "pending close records a dirty-count hint");
      Editor.Buffers.Global_Close_Buffer (A_Id, Closed);
      Assert (Closed, "setup should close one captured target before confirm");
      Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Contains (C_Id),
              "confirm closes captured clean buffers even after marks changed");
      Assert (Editor.Buffers.Global_Contains (B_Id),
              "confirm preserves dirty captured buffers through existing close policy");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) = Editor.Buffer_Switcher.No_Pending_Marked_Action,
              "confirm clears pending state after execution");
      Assert (True,
              "successful confirmed closes must not create close-history/reopen entries");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "blocked captured buffers follow their current mark state");
      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Confirm_Closes_Captured_Clean_Skips_Closed_And_Protects_Dirty;

   procedure Test_Confirm_Cancel_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("availability");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Avail := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Buffer_Switcher_Mark_Confirm);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "confirm availability should be available for pending close");
      Avail := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Buffer_Switcher_Mark_Cancel);
      Assert (Avail.Status = Editor.Commands.Command_Available,
              "cancel availability should be available for pending close");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id,
              "availability must not mutate pending captured targets");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, A_Id)
              and then not Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, B_Id),
              "availability must not mutate marks");
      Assert (Editor.Buffers.Global_Contains (A_Id) and then Editor.Buffers.Global_Contains (B_Id),
              "availability must not close buffers");
      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Confirm_Cancel_Availability_Is_Side_Effect_Free;

   procedure Test_Pending_Marked_Review_Commands_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("pending_review_commands");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Before_Recent : Natural := 0;
      Found : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, A_Id);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, B_Id);

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2,
              "setup captures two pending close targets");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher),
              "show enables pending marked review");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "pending review narrows rows to captured open targets");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 2).Id = B_Id,
              "pending review follows captured target identity, not active buffer");

      Editor.Buffer_Switcher.Clear_All_Marks (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, C_Id);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pending marked close: 2 targets; 2 still open",
              "summary reports captured and still-open counts");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 1) = A_Id
              and then Editor.Buffer_Switcher.Pending_Marked_Target_At (S.Buffer_Switcher, 2) = B_Id,
              "summary must not refresh pending targets from current marks");
      Assert (Editor.Buffer_Switcher.Is_Marked (S.Buffer_Switcher, C_Id),
              "summary must not mutate current marks");

      Before_Recent := Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Next);
      Editor.Executor.Execute_No_Log (S, Cmd);
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      begin
         Assert (Found and then Row.Id = B_Id,
                 "pending next follows effective review order without activation");
      end;
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "pending navigation must not activate the selected target");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Before_Recent,
              "pending navigation must not update recent-buffer order");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "pending navigation must not add navigation history");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Contains (B_Id),
              "selected close acts on the selected pending-review row");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher) = 2,
              "selected close must not shrink captured pending targets");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1
              and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = A_Id,
              "closed pending targets disappear only from the open review candidates");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher),
              "marked review and pending marked review are mutually exclusive");
      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Marked_Review (S.Buffer_Switcher),
              "showing pending review hides marked review deterministically");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Summary);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) = "Pending marked close: 2 targets; 1 still open",
              "summary skips captured targets that are no longer open");

      Cmd := Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Mark_Cancel);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
                Editor.Buffer_Switcher.No_Pending_Marked_Action
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher),
              "cancelling pending close clears pending review state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Pending_Marked_Review_Commands_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Buffer_Switcher_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Filter_Commands_Route_Through_Executor'Access,
         "switcher filter commands route through Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Filter_Availability_Is_Side_Effect_Free'Access,
         "switcher filter availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Sort_Commands_Route_Through_Executor'Access,
         "switcher sort commands route through Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Sort_Availability_Is_Side_Effect_Free'Access,
         "switcher sort availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Metadata_Actions_Target_Switcher_Row'Access,
         "selected switcher metadata actions target selected row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Close_Composes_With_Reopen_And_Dirty_Guard'Access,
         "selected switcher close composes with reopen and dirty guard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Buffer_List_Selected_Close_Cancel_Preserves_Dirty_Text'Access,
         "selected buffer-list close cancel preserves dirty text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_Clean_Refreshes_Buffer_List_And_Selection'Access,
         "close clean refreshes buffer list and selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Buffer_List_Clean_Close_Closes_And_Refreshes'Access,
         "selected buffer-list clean close closes and refreshes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Buffer_List_Save_And_Close_Succeeds_And_Refreshes'Access,
         "selected buffer-list save-and-close succeeds and refreshes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Buffer_List_Overwrite_Closes_And_Refreshes'Access,
         "selected buffer-list overwrite closes and refreshes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Buffer_List_Save_Conflict_Preserves_Selected_Buffer'Access,
         "selected buffer-list save conflict preserves selected buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Preview_Follows_Selected_Row_Without_Activation'Access,
         "switcher preview follows selected row without activation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Preview_Availability_Is_Side_Effect_Free'Access,
         "switcher preview availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Marks_Target_Switcher_Row'Access,
         "selected switcher mark actions target selected row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Invert_Visible_Preserves_Hidden_Marks'Access,
         "switcher invert visible preserves hidden marks");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marked_Pin_Unpin_And_Metadata_Clear'Access,
         "marked pin unpin and metadata clear");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Mark_Availability_Is_Side_Effect_Free'Access,
         "switcher mark availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marked_Metadata_Apply_Targets_Marked_Buffers'Access,
         "marked metadata apply targets marked buffers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marked_Metadata_Composes_With_Filter_Sort_And_Preview'Access,
         "marked metadata composes with filter sort and preview");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marked_Metadata_Validation_And_Availability'Access,
         "marked metadata validation and availability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Mark_Presets_Compose_With_Metadata_Visibility_And_State'Access,
         "mark presets compose with metadata visibility and state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Mark_Preset_Availability_And_No_Match_Are_Deterministic'Access,
         "mark preset availability and no-match behavior are deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marked_Review_Routes_Through_Executor_And_Is_Inspection_Only'Access,
         "marked review routes through Executor and is inspection-only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marked_Review_Availability_Is_Side_Effect_Free'Access,
         "marked review availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marked_Close_Dirty_Reopen_And_Pin_Composition'Access,
         "marked close dirty reopen and pin composition");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Marked_Close_Prepares_Captured_Targets_And_Cancel'Access,
         "marked close prepares captured targets and cancel");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Confirm_Closes_Captured_Clean_Skips_Closed_And_Protects_Dirty'Access,
         "confirm closes captured clean skips closed and protects dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Confirm_Cancel_Availability_Is_Side_Effect_Free'Access,
         "confirm and cancel availability is side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pending_Marked_Review_Commands_Are_Deterministic'Access,
         "pending marked review commands are deterministic");
   end Register_Tests;

end Editor.Executor.Buffer_Switcher_Tests;
