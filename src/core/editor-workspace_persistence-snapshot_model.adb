with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Editor.Workspace_Persistence.Text_Format; use Editor.Workspace_Persistence.Text_Format;
with Editor.Workspace_Persistence.Path_Validation; use Editor.Workspace_Persistence.Path_Validation;
with Editor.Workspace_Persistence.Parsing; use Editor.Workspace_Persistence.Parsing;
with Editor.Workspace_Persistence.File_IO; use Editor.Workspace_Persistence.File_IO;
with Editor.Workspace_Persistence.Audits; use Editor.Workspace_Persistence.Audits;

package body Editor.Workspace_Persistence.Snapshot_Model is

   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;

   function Has_Open_File_Path
     (Snapshot : Workspace_Snapshot;
      Path     : String) return Boolean
   is
   begin
      for Item of Snapshot.Open_Files loop
         if To_String (Item.Path) = Path then
            return True;
         end if;
      end loop;
      return False;
   end Has_Open_File_Path;

   function Has_Expanded_Path
     (Snapshot : Workspace_Snapshot;
      Path     : String) return Boolean
   is
   begin
      for Item of Snapshot.Expanded_Paths loop
         if To_String (Item) = Path then
            return True;
         end if;
      end loop;
      return False;
   end Has_Expanded_Path;

   procedure Mark_Partial
     (Status : in out Workspace_Persistence_Status)
   is
   begin
      if Status = Workspace_Persistence_Ok then
         Status := Workspace_Persistence_Partial_Restore;
      end if;
   end Mark_Partial;

   procedure Add_Diagnostic
     (Snapshot : in out Workspace_Snapshot;
      Kind     : Workspace_Diagnostic_Kind;
      Line_No  : Natural;
      Text     : String)
   is
   begin
      Snapshot.Diagnostics.Append
        (Workspace_Diagnostic'
          (Kind        => Kind,
          Line_Number => Line_No,
          Text        => To_Unbounded_String (Text)));
   end Add_Diagnostic;

   procedure Sort_Expanded_Paths (Snapshot : in out Workspace_Snapshot) is
      Swapped : Boolean;
   begin
      if Snapshot.Expanded_Paths.Length < 2 then
         return;
      end if;

      loop
         Swapped := False;
         for I in Snapshot.Expanded_Paths.First_Index .. Snapshot.Expanded_Paths.Last_Index - 1 loop
            if To_String (Snapshot.Expanded_Paths.Element (I)) >
               To_String (Snapshot.Expanded_Paths.Element (I + 1))
            then
               declare
                  Left : constant Unbounded_String := Snapshot.Expanded_Paths.Element (I);
               begin
                  Snapshot.Expanded_Paths.Replace_Element
                    (I, Snapshot.Expanded_Paths.Element (I + 1));
                  Snapshot.Expanded_Paths.Replace_Element (I + 1, Left);
               end;
               Swapped := True;
            end if;
         end loop;
         exit when not Swapped;
      end loop;
   end Sort_Expanded_Paths;

   procedure Clear
     (Snapshot : in out Workspace_Snapshot)
   is
   begin
      Snapshot.Format_Version := Current_Format_Version;
      Snapshot.Has_Root := False;
      Snapshot.Root := Null_Unbounded_String;
      Snapshot.Open_Files.Clear;
      Snapshot.Open_File_Requests := 0;
      Snapshot.Has_Active := False;
      Snapshot.Active_Path := Null_Unbounded_String;
      Snapshot.Active_Rel := True;
      Snapshot.Expanded_Paths.Clear;
      Snapshot.File_Tree_Visible := True;
      Snapshot.File_Tree_Width := Default_File_Tree_Width;
      Snapshot.Bottom_Visible := False;
      Snapshot.Bottom_Height := Default_Bottom_Height;
      Snapshot.Bottom_Content := Workspace_Problems_Content;
      Snapshot.Has_Recent_Project := False;
      Snapshot.Recent_Project := Null_Unbounded_String;
      Snapshot.Quick_Open_Scope := Null_Unbounded_String;
      Snapshot.Quick_Open_Filter := Workspace_Quick_Open_All_Files;
      Snapshot.Feature_Panel_Visible := False;
      Snapshot.Active_Feature_Panel := Workspace_Outline_Feature;
      Snapshot.Diagnostics.Clear;
   end Clear;

   function Version
     (Snapshot : Workspace_Snapshot) return Natural
   is
   begin
      return Snapshot.Format_Version;
   end Version;

   procedure Set_Project_Root
     (Snapshot : in out Workspace_Snapshot;
      Path     : String)
   is
      Clean : constant String := Path;
   begin
      Snapshot.Has_Root := Clean'Length > 0
        and then Clean = Trim (Clean)
        and then not Has_Control_Character (Clean);
      Snapshot.Root := To_Unbounded_String
        ((if Snapshot.Has_Root then Clean else ""));
   end Set_Project_Root;

   function Has_Project_Root
     (Snapshot : Workspace_Snapshot) return Boolean
   is
   begin
      return Snapshot.Has_Root;
   end Has_Project_Root;

   function Project_Root
     (Snapshot : Workspace_Snapshot) return String
   is
   begin
      return To_String (Snapshot.Root);
   end Project_Root;

   procedure Add_Open_File
     (Snapshot : in out Workspace_Snapshot;
      Item    : Workspace_File_Entry)
   is
      Valid : Boolean := False;
      Path  : constant String := Normalize_Project_Relative_Path
        (To_String (Item.Path), Valid);
      Copy  : Workspace_File_Entry := Item;
   begin
      if (not Item.Is_Project_Relative) or else (not Valid) then
         return;
      end if;

      Snapshot.Open_File_Requests := Snapshot.Open_File_Requests + 1;
      if Has_Open_File_Path (Snapshot, Path) then
         return;
      end if;

      Copy.Path := To_Unbounded_String (Path);
      Copy.Is_Project_Relative := True;
      Snapshot.Open_Files.Append (Copy);
   end Add_Open_File;

   function Open_File_Count
     (Snapshot : Workspace_Snapshot) return Natural
   is
   begin
      return Natural (Snapshot.Open_Files.Length);
   end Open_File_Count;

   function Open_File_Request_Count
     (Snapshot : Workspace_Snapshot) return Natural
   is
   begin
      return Snapshot.Open_File_Requests;
   end Open_File_Request_Count;

   function Open_File
     (Snapshot : Workspace_Snapshot;
      Index    : Positive) return Workspace_File_Entry
   is
   begin
      return Snapshot.Open_Files.Element (Index - 1);
   end Open_File;

   procedure Set_Active_File_Path
     (Snapshot            : in out Workspace_Snapshot;
      Path                : String;
      Is_Project_Relative : Boolean := True)
   is
      Valid : Boolean := False;
      Clean : constant String := Normalize_Project_Relative_Path (Path, Valid);
   begin
      Snapshot.Has_Active := Is_Project_Relative and then Valid;
      Snapshot.Active_Path := To_Unbounded_String
        ((if Snapshot.Has_Active then Clean else ""));
      Snapshot.Active_Rel := True;
   end Set_Active_File_Path;

   function Has_Active_File_Path
     (Snapshot : Workspace_Snapshot) return Boolean
   is
   begin
      return Snapshot.Has_Active;
   end Has_Active_File_Path;

   function Active_File_Path
     (Snapshot : Workspace_Snapshot) return String
   is
   begin
      return To_String (Snapshot.Active_Path);
   end Active_File_Path;

   function Active_File_Is_Project_Relative
     (Snapshot : Workspace_Snapshot) return Boolean
   is
   begin
      return Snapshot.Active_Rel;
   end Active_File_Is_Project_Relative;

   procedure Add_Expanded_File_Tree_Path
     (Snapshot : in out Workspace_Snapshot;
      Path     : String)
   is
      Valid : Boolean := False;
      Clean : constant String := Normalize_Project_Relative_Path (Path, Valid);
   begin
      if (not Valid) or else Has_Expanded_Path (Snapshot, Clean) then
         return;
      end if;
      Snapshot.Expanded_Paths.Append (To_Unbounded_String (Clean));
   end Add_Expanded_File_Tree_Path;

   function Expanded_File_Tree_Path_Count
     (Snapshot : Workspace_Snapshot) return Natural
   is
   begin
      return Natural (Snapshot.Expanded_Paths.Length);
   end Expanded_File_Tree_Path_Count;

   function Expanded_File_Tree_Path
     (Snapshot : Workspace_Snapshot;
      Index    : Positive) return String
   is
   begin
      return To_String (Snapshot.Expanded_Paths.Element (Index - 1));
   end Expanded_File_Tree_Path;

   procedure Set_File_Tree_Panel
     (Snapshot : in out Workspace_Snapshot;
      Visible  : Boolean;
      Width    : Natural)
   is
   begin
      Snapshot.File_Tree_Visible := Visible;
      Snapshot.File_Tree_Width :=
        (if Width = 0 then Default_File_Tree_Width else Width);
   end Set_File_Tree_Panel;

   function File_Tree_Panel_Visible
     (Snapshot : Workspace_Snapshot) return Boolean
   is
   begin
      return Snapshot.File_Tree_Visible;
   end File_Tree_Panel_Visible;

   function File_Tree_Panel_Width
     (Snapshot : Workspace_Snapshot) return Natural
   is
   begin
      return Snapshot.File_Tree_Width;
   end File_Tree_Panel_Width;

   procedure Set_Bottom_Panel
     (Snapshot : in out Workspace_Snapshot;
      Visible  : Boolean;
      Height   : Natural;
      Content  : Bottom_Content_Id)
   is
   begin
      Snapshot.Bottom_Visible := Visible;
      Snapshot.Bottom_Height :=
        (if Height = 0 then Default_Bottom_Height else Height);
      Snapshot.Bottom_Content := Content;
   end Set_Bottom_Panel;

   function Bottom_Panel_Visible
     (Snapshot : Workspace_Snapshot) return Boolean
   is
   begin
      return Snapshot.Bottom_Visible;
   end Bottom_Panel_Visible;

   function Bottom_Panel_Height
     (Snapshot : Workspace_Snapshot) return Natural
   is
   begin
      return Snapshot.Bottom_Height;
   end Bottom_Panel_Height;

   function Active_Bottom_Content
     (Snapshot : Workspace_Snapshot) return Bottom_Content_Id
   is
   begin
      return Snapshot.Bottom_Content;
   end Active_Bottom_Content;

   procedure Set_Recent_Project_Path
     (Snapshot : in out Workspace_Snapshot;
      Path     : String)
   is
      Clean : constant String := Path;
   begin
      Snapshot.Has_Recent_Project := Clean'Length > 0
        and then Clean = Trim (Clean)
        and then not Has_Control_Character (Clean);
      Snapshot.Recent_Project := To_Unbounded_String
        ((if Snapshot.Has_Recent_Project then Clean else ""));
   end Set_Recent_Project_Path;

   function Has_Recent_Project_Path
     (Snapshot : Workspace_Snapshot) return Boolean
   is
   begin
      return Snapshot.Has_Recent_Project;
   end Has_Recent_Project_Path;

   function Recent_Project_Path
     (Snapshot : Workspace_Snapshot) return String
   is
   begin
      return To_String (Snapshot.Recent_Project);
   end Recent_Project_Path;

   procedure Set_Quick_Open_Path_Scope
     (Snapshot : in out Workspace_Snapshot;
      Scope    : String)
   is
      Valid : Boolean := False;
      Clean : constant String := Normalize_Directory_Scope (Scope, Valid);
   begin
      Snapshot.Quick_Open_Scope := To_Unbounded_String
        ((if Valid then Clean else ""));
   end Set_Quick_Open_Path_Scope;

   function Quick_Open_Path_Scope
     (Snapshot : Workspace_Snapshot) return String
   is
   begin
      return To_String (Snapshot.Quick_Open_Scope);
   end Quick_Open_Path_Scope;

   procedure Set_Quick_Open_File_Kind_Filter
     (Snapshot : in out Workspace_Snapshot;
      Filter   : Workspace_Quick_Open_File_Kind_Filter)
   is
   begin
      Snapshot.Quick_Open_Filter := Filter;
   end Set_Quick_Open_File_Kind_Filter;

   function Quick_Open_File_Kind_Filter
     (Snapshot : Workspace_Snapshot)
      return Workspace_Quick_Open_File_Kind_Filter
   is
   begin
      return Snapshot.Quick_Open_Filter;
   end Quick_Open_File_Kind_Filter;

   procedure Set_Feature_Panel
     (Snapshot       : in out Workspace_Snapshot;
      Visible        : Boolean;
      Active_Feature : Workspace_Feature_Panel_Id)
   is
   begin
      Snapshot.Feature_Panel_Visible := Visible;
      Snapshot.Active_Feature_Panel := Active_Feature;
   end Set_Feature_Panel;

   function Feature_Panel_Visible
     (Snapshot : Workspace_Snapshot) return Boolean
   is
   begin
      return Snapshot.Feature_Panel_Visible;
   end Feature_Panel_Visible;

   function Active_Feature_Panel
     (Snapshot : Workspace_Snapshot) return Workspace_Feature_Panel_Id
   is
   begin
      return Snapshot.Active_Feature_Panel;
   end Active_Feature_Panel;


   function Diagnostic_Count
     (Snapshot : Workspace_Snapshot) return Natural
   is
   begin
      return Natural (Snapshot.Diagnostics.Length);
   end Diagnostic_Count;

   function Diagnostic
     (Snapshot : Workspace_Snapshot;
      Index    : Positive) return Workspace_Diagnostic
   is
   begin
      return Snapshot.Diagnostics.Element (Index - 1);
   end Diagnostic;

   procedure Normalize
     (Snapshot : in out Workspace_Snapshot)
   is
      Normalized_Open : File_Entry_Vectors.Vector;
      Normalized_Expanded : String_Vectors.Vector;
      Valid : Boolean;
   begin
      for Item of Snapshot.Open_Files loop
         if Item.Is_Project_Relative then
            declare
               Clean : constant String := Normalize_Project_Relative_Path
                 (To_String (Item.Path), Valid);
               Copy  : Workspace_File_Entry := Item;
               Seen  : Boolean := False;
            begin
               if Valid then
                  for Existing of Normalized_Open loop
                     if To_String (Existing.Path) = Clean then
                        Seen := True;
                     end if;
                  end loop;

                  if not Seen then
                     Copy.Path := To_Unbounded_String (Clean);
                     Copy.Is_Project_Relative := True;
                     Normalized_Open.Append (Copy);
                  end if;
               end if;
            end;
         end if;
      end loop;

      Snapshot.Open_Files := Normalized_Open;

      if Snapshot.Has_Active then
         declare
            Clean : constant String := Normalize_Project_Relative_Path
              (To_String (Snapshot.Active_Path), Valid);
         begin
            Snapshot.Has_Active := Snapshot.Active_Rel
              and then Valid
              and then Has_Open_File_Path (Snapshot, Clean);
            Snapshot.Active_Rel := True;
            Snapshot.Active_Path := To_Unbounded_String
              ((if Snapshot.Has_Active then Clean else ""));
         end;
      end if;

      for Path_Item of Snapshot.Expanded_Paths loop
         declare
            Clean : constant String := Normalize_Project_Relative_Path
              (To_String (Path_Item), Valid);
            Seen : Boolean := False;
         begin
            if Valid then
               for Existing of Normalized_Expanded loop
                  if To_String (Existing) = Clean then
                     Seen := True;
                  end if;
               end loop;
               if not Seen then
                  Normalized_Expanded.Append (To_Unbounded_String (Clean));
               end if;
            end if;
         end;
      end loop;

      Snapshot.Expanded_Paths := Normalized_Expanded;

      if Snapshot.File_Tree_Width = 0 then
         Snapshot.File_Tree_Width := Default_File_Tree_Width;
      end if;
      if Snapshot.Bottom_Height = 0 then
         Snapshot.Bottom_Height := Default_Bottom_Height;
      end if;

      if Snapshot.Has_Recent_Project
        and then (To_String (Snapshot.Recent_Project)'Length = 0
                  or else To_String (Snapshot.Recent_Project) /=
                    Trim (To_String (Snapshot.Recent_Project))
                  or else Has_Control_Character (To_String (Snapshot.Recent_Project)))
      then
         Snapshot.Has_Recent_Project := False;
         Snapshot.Recent_Project := Null_Unbounded_String;
      end if;

      declare
         Scope_Valid : Boolean := False;
         Scope       : constant String := Normalize_Directory_Scope
           (To_String (Snapshot.Quick_Open_Scope), Scope_Valid);
      begin
         Snapshot.Quick_Open_Scope := To_Unbounded_String
           ((if Scope_Valid then Scope else ""));
      end;

      Sort_Expanded_Paths (Snapshot);
   end Normalize;

   function Equivalent
     (Left  : Workspace_Snapshot;
      Right : Workspace_Snapshot) return Boolean
   is
      L : Workspace_Snapshot := Left;
      R : Workspace_Snapshot := Right;
   begin
      Normalize (L);
      Normalize (R);

      if L.Format_Version /= R.Format_Version
        or else L.Has_Root /= R.Has_Root
        or else To_String (L.Root) /= To_String (R.Root)
        or else L.Has_Active /= R.Has_Active
        or else To_String (L.Active_Path) /= To_String (R.Active_Path)
        or else L.Active_Rel /= R.Active_Rel
        or else L.File_Tree_Visible /= R.File_Tree_Visible
        or else L.File_Tree_Width /= R.File_Tree_Width
        or else L.Bottom_Visible /= R.Bottom_Visible
        or else L.Bottom_Height /= R.Bottom_Height
        or else L.Bottom_Content /= R.Bottom_Content
        or else L.Has_Recent_Project /= R.Has_Recent_Project
        or else To_String (L.Recent_Project) /= To_String (R.Recent_Project)
        or else To_String (L.Quick_Open_Scope) /= To_String (R.Quick_Open_Scope)
        or else L.Quick_Open_Filter /= R.Quick_Open_Filter
        or else L.Feature_Panel_Visible /= R.Feature_Panel_Visible
        or else L.Active_Feature_Panel /= R.Active_Feature_Panel
        or else L.Open_Files.Length /= R.Open_Files.Length
        or else L.Expanded_Paths.Length /= R.Expanded_Paths.Length
      then
         return False;
      end if;

      if L.Open_Files.Length > 0 then
         for I in L.Open_Files.First_Index .. L.Open_Files.Last_Index loop
            declare
               LE : constant Workspace_File_Entry := L.Open_Files.Element (I);
               RE : constant Workspace_File_Entry := R.Open_Files.Element (I);
            begin
               if To_String (LE.Path) /= To_String (RE.Path)
                 or else LE.Is_Project_Relative /= RE.Is_Project_Relative
                 or else LE.Cursor_Row /= RE.Cursor_Row
                 or else LE.Cursor_Column /= RE.Cursor_Column
                 or else LE.View_First_Row /= RE.View_First_Row
               then
                  return False;
               end if;
            end;
         end loop;
      end if;

      if L.Expanded_Paths.Length > 0 then
         for I in L.Expanded_Paths.First_Index .. L.Expanded_Paths.Last_Index loop
            if To_String (L.Expanded_Paths.Element (I)) /=
               To_String (R.Expanded_Paths.Element (I))
            then
               return False;
            end if;
         end loop;
      end if;

      return True;
   end Equivalent;

   function Debug_Summary
     (Snapshot : Workspace_Snapshot) return String
   is
   begin
      return "version=" & Natural_Text (Snapshot.Format_Version)
        & " root=" & (if Snapshot.Has_Root then To_String (Snapshot.Root) else "<none>")
        & " open=" & Natural_Text (Natural (Snapshot.Open_Files.Length))
        & " active=" & (if Snapshot.Has_Active then To_String (Snapshot.Active_Path) else "<none>")
        & " expanded=" & Natural_Text (Natural (Snapshot.Expanded_Paths.Length))
        & " quick-scope=" & (if Length (Snapshot.Quick_Open_Scope) > 0 then To_String (Snapshot.Quick_Open_Scope) else "<none>")
        & " quick-filter=" & Quick_Open_Filter_Text (Snapshot.Quick_Open_Filter)
        & " feature-panel=" & Feature_Panel_Text (Snapshot.Active_Feature_Panel)
        & " diagnostics=" & Natural_Text (Natural (Snapshot.Diagnostics.Length));
   end Debug_Summary;



   function Serialized_Text
     (Snapshot : Workspace_Snapshot) return String
   is
      Copy   : Workspace_Snapshot := Snapshot;
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Put_Line (Line : String) is
      begin
         Append (Result, Line);
         Append (Result, ASCII.LF);
      end Put_Line;
   begin
      Normalize (Copy);

      Put_Line ("editor-workspace-version=" & Natural_Text (Current_Format_Version));
      if Copy.Has_Root then
         Put_Line ("project-root=" & To_String (Copy.Root));
      end if;

      Put_Line ("[open-files]");
      for Item of Copy.Open_Files loop
         Put_Line
           (To_String (Item.Path)
            & "|relative=" & Bool_Text (Item.Is_Project_Relative)
            & "|row=" & Natural_Text (Item.Cursor_Row)
            & "|col=" & Natural_Text (Item.Cursor_Column)
            & "|view=" & Natural_Text (Item.View_First_Row));
      end loop;

      Put_Line ("[active-file]");
      if Copy.Has_Active then
         Put_Line
           (To_String (Copy.Active_Path)
            & "|relative=" & Bool_Text (Copy.Active_Rel));
      end if;

      Put_Line ("[file-tree-expanded]");
      for Path_Item of Copy.Expanded_Paths loop
         Put_Line (To_String (Path_Item));
      end loop;

      Put_Line ("[panels]");
      Put_Line ("file-tree-visible=" & Bool_Text (Copy.File_Tree_Visible));
      Put_Line ("file-tree-width=" & Natural_Text (Copy.File_Tree_Width));
      Put_Line ("bottom-visible=" & Bool_Text (Copy.Bottom_Visible));
      Put_Line ("bottom-height=" & Natural_Text (Copy.Bottom_Height));
      Put_Line ("bottom-content=" & Content_Text (Copy.Bottom_Content));

      Put_Line ("[continuity]");
      Put_Line ("recent-project="
                & (if Copy.Has_Recent_Project then To_String (Copy.Recent_Project) else ""));
      Put_Line ("quick-open-scope=" & To_String (Copy.Quick_Open_Scope));
      Put_Line ("quick-open-filter=" & Quick_Open_Filter_Text (Copy.Quick_Open_Filter));
      Put_Line ("feature-panel-visible=" & Bool_Text (Copy.Feature_Panel_Visible));
      Put_Line ("active-feature-panel=" & Feature_Panel_Text (Copy.Active_Feature_Panel));

      return To_String (Result);
   end Serialized_Text;



end Editor.Workspace_Persistence.Snapshot_Model;
