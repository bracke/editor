with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.File_Tree is
   use type Ada.Directories.File_Kind;

   Max_File_Tree_Nodes : constant Natural := 20_000;
   Max_File_Tree_Depth : constant Natural := 64;

   type Entry_Kind is (Entry_Directory, Entry_File);

   type Scan_Entry is record
      Name : Unbounded_String;
      Kind : Entry_Kind := Entry_File;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Scan_Entry);

   function Is_Separator (Ch : Character) return Boolean is
   begin
      return Ch = '/' or else Ch = '\';
   end Is_Separator;

   function Strip_Trailing_Separators (Path : String) return String is
      Last : Integer := Path'Last;
   begin
      if Path'Length = 0 then
         return Path;
      end if;

      while Last > Path'First and then Is_Separator (Path (Last)) loop
         Last := Last - 1;
      end loop;

      return Path (Path'First .. Last);
   end Strip_Trailing_Separators;

   function Normalize_For_Compare (Path : String) return String is
      Stripped : constant String := Strip_Trailing_Separators (Path);
      Result   : String (Stripped'Range);
   begin
      for I in Stripped'Range loop
         if Stripped (I) = '\' then
            Result (I) := '/';
         else
            Result (I) := Stripped (I);
         end if;
      end loop;
      return Result;
   end Normalize_For_Compare;

   function Simple_Display_Name (Path : String) return String is
      Stripped : constant String := Strip_Trailing_Separators (Path);
   begin
      if Stripped'Length = 0 then
         return "";
      end if;

      declare
         Name : constant String := Ada.Directories.Simple_Name (Stripped);
      begin
         if Name'Length = 0 then
            return Stripped;
         else
            return Name;
         end if;
      end;
   exception
      when others =>
         return Stripped;
   end Simple_Display_Name;

   function Join_Relative_Path
     (Parent : String;
      Name   : String) return String
   is
   begin
      if Parent = "." then
         return Name;
      else
         return Parent & "/" & Name;
      end if;
   end Join_Relative_Path;

   function Is_Before (Left, Right : Scan_Entry) return Boolean is
   begin
      if Left.Kind /= Right.Kind then
         return Left.Kind = Entry_Directory;
      else
         return To_String (Left.Name) < To_String (Right.Name);
      end if;
   end Is_Before;

   procedure Sort_Entries (Entries : in out Entry_Vectors.Vector) is
      Tmp : Scan_Entry;
   begin
      if Entries.Length < 2 then
         return;
      end if;

      for I in Entries.First_Index + 1 .. Entries.Last_Index loop
         Tmp := Entries (I);
         declare
            J : Natural := I;
         begin
            while J > Entries.First_Index
              and then Is_Before (Tmp, Entries (J - 1))
            loop
               Entries.Replace_Element (J, Entries (J - 1));
               J := J - 1;
            end loop;
            Entries.Replace_Element (J, Tmp);
         end;
      end loop;
   end Sort_Entries;

   function Index_Of
     (Tree : File_Tree_State;
      Id   : File_Tree_Node_Id) return Natural
   is
   begin
      if Id = No_File_Tree_Node or else Tree.Nodes.Length = 0 then
         return Natural'Last;
      end if;

      for I in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         if Tree.Nodes (I).Id = Id then
            return I;
         end if;
      end loop;

      return Natural'Last;
   end Index_Of;

   function Contains
     (Tree : File_Tree_State;
      Id   : File_Tree_Node_Id) return Boolean
   is
   begin
      return Index_Of (Tree, Id) /= Natural'Last;
   end Contains;

   function Allocate_Id
     (Tree : in out File_Tree_State) return File_Tree_Node_Id
   is
      Result : constant File_Tree_Node_Id := Tree.Next_Id;
   begin
      Tree.Next_Id := Tree.Next_Id + 1;
      return Result;
   end Allocate_Id;

   procedure Add_Child
     (Tree   : in out File_Tree_State;
      Parent : File_Tree_Node_Id;
      Child  : File_Tree_Node_Id)
   is
      Parent_Index : constant Natural := Index_Of (Tree, Parent);
      Rec          : File_Tree_Node_Record;
   begin
      if Parent_Index = Natural'Last then
         return;
      end if;

      Rec := Tree.Nodes (Parent_Index);
      Rec.Children.Append (Child);
      Tree.Nodes.Replace_Element (Parent_Index, Rec);
   end Add_Child;

   function Add_Node
     (Tree          : in out File_Tree_State;
      Parent        : File_Tree_Node_Id;
      Kind          : File_Tree_Node_Kind;
      Name          : String;
      Absolute_Path : String;
      Relative_Path : String;
      Depth         : Natural;
      Is_Expanded   : Boolean) return File_Tree_Node_Id
   is
      Id : constant File_Tree_Node_Id := Allocate_Id (Tree);
   begin
      Tree.Nodes.Append
        (File_Tree_Node_Record'
           (Id            => Id,
            Parent        => Parent,
            Kind          => Kind,
            Name          => To_Unbounded_String (Name),
            Absolute_Path => To_Unbounded_String (Absolute_Path),
            Relative_Path => To_Unbounded_String (Relative_Path),
            Depth         => Depth,
            Is_Expanded   => Is_Expanded,
            Children      => Node_Id_Vectors.Empty_Vector));

      if Parent /= No_File_Tree_Node then
         Add_Child (Tree, Parent, Id);
      end if;

      return Id;
   end Add_Node;

   procedure Collect_Entries
     (Directory_Path : String;
      Entries        : out Entry_Vectors.Vector)
   is
      Search         : Ada.Directories.Search_Type;
      Search_Started : Boolean := False;
   begin
      Entries.Clear;
      Ada.Directories.Start_Search
        (Search    => Search,
         Directory => Directory_Path,
         Pattern   => "*");
      Search_Started := True;

      while Ada.Directories.More_Entries (Search) loop
         declare
            Dir_Entry : Ada.Directories.Directory_Entry_Type;
         begin
            Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
            declare
               Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
            begin
               if Name /= "." and then Name /= ".." then
                  case Ada.Directories.Kind (Dir_Entry) is
                     when Ada.Directories.Directory =>
                        Entries.Append
                          (Scan_Entry'
                            (Name => To_Unbounded_String (Name),
                            Kind => Entry_Directory));
                     when Ada.Directories.Ordinary_File =>
                        Entries.Append
                          (Scan_Entry'
                            (Name => To_Unbounded_String (Name),
                            Kind => Entry_File));
                     when Ada.Directories.Special_File =>
                        null;
                  end case;
               end if;
            end;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
      Search_Started := False;
      Sort_Entries (Entries);
   exception
      when others =>
         if Search_Started then
            begin
               Ada.Directories.End_Search (Search);
            exception
               when others =>
                  null;
            end;
         end if;
         raise;
   end Collect_Entries;

   procedure Scan_Directory
     (Tree          : in out File_Tree_State;
      Parent        : File_Tree_Node_Id;
      Directory_Path : String;
      Parent_Relative : String;
      Depth         : Natural)
   is
      Entries : Entry_Vectors.Vector;
   begin
      if Natural (Tree.Nodes.Length) >= Max_File_Tree_Nodes then
         if Length (Tree.Last_Result.Error_Text) = 0 then
            Tree.Last_Result.Error_Text :=
              To_Unbounded_String ("file tree node limit reached");
         end if;
         return;
      elsif Depth > Max_File_Tree_Depth then
         if Length (Tree.Last_Result.Error_Text) = 0 then
            Tree.Last_Result.Error_Text :=
              To_Unbounded_String ("file tree depth limit reached");
         end if;
         return;
      end if;

      Collect_Entries (Directory_Path, Entries);

      for Item of Entries loop
         exit when Natural (Tree.Nodes.Length) >= Max_File_Tree_Nodes;
         declare
            Name : constant String := To_String (Item.Name);
            Abs_Path : constant String := Ada.Directories.Compose (Directory_Path, Name);
            Rel      : constant String := Join_Relative_Path (Parent_Relative, Name);
            Id   : File_Tree_Node_Id := No_File_Tree_Node;
         begin
            if Item.Kind = Entry_Directory then
               Id := Add_Node
                 (Tree          => Tree,
                  Parent        => Parent,
                  Kind          => Directory_Node,
                  Name          => Name,
                  Absolute_Path => Abs_Path,
                  Relative_Path => Rel,
                  Depth         => Depth,
                  Is_Expanded   => False);
               begin
                  if Natural (Tree.Nodes.Length) >= Max_File_Tree_Nodes then
                     if Length (Tree.Last_Result.Error_Text) = 0 then
                        Tree.Last_Result.Error_Text :=
                          To_Unbounded_String ("file tree node limit reached");
                     end if;
                  else
                     Scan_Directory
                       (Tree            => Tree,
                        Parent          => Id,
                        Directory_Path  => Abs_Path,
                        Parent_Relative => Rel,
                        Depth           => Depth + 1);
                  end if;
               exception
                  when others =>
                     if Tree.Last_Result.Status = File_Tree_Scan_Ok then
                        Tree.Last_Result.Error_Text :=
                          To_Unbounded_String ("one or more child directories could not be read");
                     end if;
               end;
            else
               Id := Add_Node
                 (Tree          => Tree,
                  Parent        => Parent,
                  Kind          => File_Node,
                  Name          => Name,
                  Absolute_Path => Abs_Path,
                  Relative_Path => Rel,
                  Depth         => Depth,
                  Is_Expanded   => False);
            end if;
         end;
      end loop;
   end Scan_Directory;

   procedure Append_Visible_Subtree
     (Tree : in out File_Tree_State;
      Id   : File_Tree_Node_Id)
   is
      Node_Index : constant Natural := Index_Of (Tree, Id);
      Rec        : File_Tree_Node_Record;
   begin
      if Node_Index = Natural'Last then
         return;
      end if;

      Rec := Tree.Nodes (Node_Index);
      Tree.Visible_Rows.Append
        (Visible_File_Tree_Row'
          (Node_Id => Rec.Id,
          Depth   => Rec.Depth));

      if Rec.Kind = Directory_Node and then Rec.Is_Expanded then
         for Child of Rec.Children loop
            Append_Visible_Subtree (Tree, Child);
         end loop;
      end if;
   end Append_Visible_Subtree;

   procedure Clear
     (Tree : in out File_Tree_State)
   is
   begin
      Tree.Nodes.Clear;
      Tree.Visible_Rows.Clear;
      Tree.Root_Id := No_File_Tree_Node;
      Tree.Next_Id := 1;
      Tree.Last_Result :=
        (Status     => File_Tree_No_Project,
         Root_Path  => Null_Unbounded_String,
         Node_Count => 0,
         Error_Text => Null_Unbounded_String);
   end Clear;

   function Is_Empty
     (Tree : File_Tree_State) return Boolean
   is
   begin
      return Tree.Nodes.Length = 0;
   end Is_Empty;

   function Root
     (Tree : File_Tree_State) return File_Tree_Node_Id
   is
   begin
      return Tree.Root_Id;
   end Root;

   function Node
     (Tree : File_Tree_State;
      Id   : File_Tree_Node_Id) return File_Tree_Node_Summary
   is
      Node_Index : constant Natural := Index_Of (Tree, Id);
      Rec        : File_Tree_Node_Record;
   begin
      if Node_Index = Natural'Last then
         return (others => <>);
      end if;

      Rec := Tree.Nodes (Node_Index);
      return
        (Id            => Rec.Id,
         Parent        => Rec.Parent,
         Kind          => Rec.Kind,
         Name          => Rec.Name,
         Absolute_Path => Rec.Absolute_Path,
         Relative_Path => Rec.Relative_Path,
         Depth         => Rec.Depth,
         Is_Expanded   => Rec.Is_Expanded,
         Has_Children  => Rec.Children.Length > 0);
   end Node;

   function Node_Count
     (Tree : File_Tree_State) return Natural
   is
   begin
      return Natural (Tree.Nodes.Length);
   end Node_Count;

   function File_Node_Count
     (Tree : File_Tree_State) return Natural
   is
      Count : Natural := 0;
   begin
      for Rec of Tree.Nodes loop
         if Rec.Kind = File_Node then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end File_Node_Count;

   function Expanded_Node_Count
     (Tree : File_Tree_State) return Natural
   is
      Count : Natural := 0;
   begin
      for Rec of Tree.Nodes loop
         if Rec.Is_Expanded then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Expanded_Node_Count;

   function File_Node_At
     (Tree  : File_Tree_State;
      Index : Positive) return File_Tree_Node_Summary
   is
      Seen : Natural := 0;
   begin
      for Rec of Tree.Nodes loop
         if Rec.Kind = File_Node then
            Seen := Seen + 1;
            if Seen = Index then
               return Node (Tree, Rec.Id);
            end if;
         end if;
      end loop;

      return (others => <>);
   end File_Node_At;

   function Is_File_Node
     (Tree : File_Tree_State;
      Id   : File_Tree_Node_Id) return Boolean
   is
      Node_Index : constant Natural := Index_Of (Tree, Id);
   begin
      return Node_Index /= Natural'Last
        and then Tree.Nodes (Node_Index).Kind = File_Node;
   end Is_File_Node;

   function Visible_Row_Count
     (Tree : File_Tree_State) return Natural
   is
   begin
      return Natural (Tree.Visible_Rows.Length);
   end Visible_Row_Count;

   function Visible_Row
     (Tree  : File_Tree_State;
      Index : Positive) return Visible_File_Tree_Row
   is
   begin
      if Index > Natural (Tree.Visible_Rows.Length) then
         return (others => <>);
      else
         return Tree.Visible_Rows (Index - 1);
      end if;
   end Visible_Row;

   function Node_At_Visible_Row
     (Tree  : File_Tree_State;
      Row   : Positive;
      Found : out Boolean) return File_Tree_Node_Id
   is
      Visible : constant Visible_File_Tree_Row := Visible_Row (Tree, Row);
   begin
      Found := Visible.Node_Id /= No_File_Tree_Node;
      return Visible.Node_Id;
   end Node_At_Visible_Row;

   function Find_By_Path
     (Tree  : File_Tree_State;
      Path  : String;
      Found : out Boolean) return File_Tree_Node_Id
   is
      Want : constant String := Normalize_For_Compare (Path);
   begin
      Found := False;
      if Want'Length = 0 then
         return No_File_Tree_Node;
      end if;

      for Rec of Tree.Nodes loop
         if Normalize_For_Compare (To_String (Rec.Absolute_Path)) = Want
           or else Normalize_For_Compare (To_String (Rec.Relative_Path)) = Want
         then
            Found := True;
            return Rec.Id;
         end if;
      end loop;

      return No_File_Tree_Node;
   end Find_By_Path;

   procedure Toggle_Expanded
     (Tree : in out File_Tree_State;
      Id   : File_Tree_Node_Id)
   is
      Node_Index : constant Natural := Index_Of (Tree, Id);
      Rec        : File_Tree_Node_Record;
   begin
      if Node_Index = Natural'Last then
         return;
      end if;

      Rec := Tree.Nodes (Node_Index);
      if Rec.Kind /= Directory_Node then
         return;
      end if;

      Rec.Is_Expanded := not Rec.Is_Expanded;
      Tree.Nodes.Replace_Element (Node_Index, Rec);
      Rebuild_Visible_Rows (Tree);
   end Toggle_Expanded;

   procedure Set_Expanded
     (Tree     : in out File_Tree_State;
      Id       : File_Tree_Node_Id;
      Expanded : Boolean)
   is
      Node_Index : constant Natural := Index_Of (Tree, Id);
      Rec        : File_Tree_Node_Record;
   begin
      if Node_Index = Natural'Last then
         return;
      end if;

      Rec := Tree.Nodes (Node_Index);
      if Rec.Kind /= Directory_Node or else Rec.Is_Expanded = Expanded then
         return;
      end if;

      Rec.Is_Expanded := Expanded;
      Tree.Nodes.Replace_Element (Node_Index, Rec);
      Rebuild_Visible_Rows (Tree);
   end Set_Expanded;


   procedure Collapse_All
     (Tree : in out File_Tree_State)
   is
      Rec : File_Tree_Node_Record;
   begin
      --  Phase 545: collapse-all is view-state only and means every directory,
      --  including the project root.  The root row remains visible because
      --  Rebuild_Visible_Rows always appends the root before consulting its
      --  expansion flag.
      if Tree.Nodes.Length > 0 then
         for I in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
            Rec := Tree.Nodes (I);
            if Rec.Kind = Directory_Node then
               Rec.Is_Expanded := False;
               Tree.Nodes.Replace_Element (I, Rec);
            end if;
         end loop;
      end if;

      Rebuild_Visible_Rows (Tree);
   end Collapse_All;

   procedure Expand_Ancestors
     (Tree : in out File_Tree_State;
      Id   : File_Tree_Node_Id)
   is
      Node_Index : constant Natural := Index_Of (Tree, Id);
      Parent     : File_Tree_Node_Id := No_File_Tree_Node;
      Parent_Index : Natural := Natural'Last;
      Rec        : File_Tree_Node_Record;
   begin
      if Node_Index = Natural'Last then
         return;
      end if;

      Parent := Tree.Nodes (Node_Index).Parent;
      while Parent /= No_File_Tree_Node loop
         Parent_Index := Index_Of (Tree, Parent);
         exit when Parent_Index = Natural'Last;
         Rec := Tree.Nodes (Parent_Index);
         if Rec.Kind = Directory_Node then
            Rec.Is_Expanded := True;
            Tree.Nodes.Replace_Element (Parent_Index, Rec);
         end if;
         Parent := Rec.Parent;
      end loop;

      Rebuild_Visible_Rows (Tree);
   end Expand_Ancestors;

   function Kind_Label
     (Kind : File_Tree_Node_Kind) return String
   is
   begin
      case Kind is
         when Directory_Node =>
            return "directory";
         when File_Node =>
            return "file";
      end case;
   end Kind_Label;


   procedure Preserve_Expanded_Paths_From
     (Tree   : in out File_Tree_State;
      Source : File_Tree_State)
   is
      Source_Id    : File_Tree_Node_Id := No_File_Tree_Node;
      Source_Found : Boolean := False;
      Source_Index : Natural := Natural'Last;
      Target_Rec   : File_Tree_Node_Record;
      Source_Rec   : File_Tree_Node_Record;
   begin
      --  Phase 545 completeness: refresh must preserve directory expansion
      --  state by stable path for every directory that still exists, not only
      --  directories that happened to be visible.  This also preserves an
      --  explicitly collapsed project root and expanded descendants hidden
      --  beneath a collapsed parent.  Newly discovered directories keep the
      --  scan defaults.
      if Tree.Nodes.Length > 0 and then Source.Nodes.Length > 0 then
         for I in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
            Target_Rec := Tree.Nodes (I);
            if Target_Rec.Kind = Directory_Node then
               Source_Id := Find_By_Path
                 (Source, To_String (Target_Rec.Relative_Path), Source_Found);
               if Source_Found and then Source_Id /= No_File_Tree_Node then
                  Source_Index := Index_Of (Source, Source_Id);
                  if Source_Index /= Natural'Last then
                     Source_Rec := Source.Nodes (Source_Index);
                     if Source_Rec.Kind = Directory_Node then
                        Target_Rec.Is_Expanded := Source_Rec.Is_Expanded;
                        Tree.Nodes.Replace_Element (I, Target_Rec);
                     end if;
                  end if;
               end if;
            end if;
         end loop;
      end if;

      Rebuild_Visible_Rows (Tree);
   end Preserve_Expanded_Paths_From;

   procedure Rebuild_Visible_Rows
     (Tree : in out File_Tree_State)
   is
   begin
      Tree.Visible_Rows.Clear;
      if Tree.Root_Id /= No_File_Tree_Node then
         Append_Visible_Subtree (Tree, Tree.Root_Id);
      end if;
   end Rebuild_Visible_Rows;

   function Scan_Project
     (Root_Path : String) return File_Tree_State
   is
      Tree : File_Tree_State;
      Root_Full : Unbounded_String;
   begin
      Clear (Tree);
      Tree.Last_Result.Root_Path := To_Unbounded_String (Root_Path);

      if Root_Path'Length = 0 then
         Tree.Last_Result.Status := File_Tree_Invalid_Root;
         Tree.Last_Result.Error_Text := To_Unbounded_String ("invalid root");
         return Tree;
      end if;

      if not Ada.Directories.Exists (Root_Path) then
         Tree.Last_Result.Status := File_Tree_Root_Not_Found;
         Tree.Last_Result.Error_Text := To_Unbounded_String ("root not found");
         return Tree;
      end if;

      if Ada.Directories.Kind (Root_Path) /= Ada.Directories.Directory then
         Tree.Last_Result.Status := File_Tree_Root_Not_Directory;
         Tree.Last_Result.Error_Text := To_Unbounded_String ("root is not a directory");
         return Tree;
      end if;

      Root_Full := To_Unbounded_String (Ada.Directories.Full_Name (Root_Path));
      Tree.Last_Result.Status := File_Tree_Scan_Ok;
      Tree.Last_Result.Root_Path := Root_Full;

      Tree.Root_Id := Add_Node
        (Tree          => Tree,
         Parent        => No_File_Tree_Node,
         Kind          => Directory_Node,
         Name          => Simple_Display_Name (To_String (Root_Full)),
         Absolute_Path => To_String (Root_Full),
         Relative_Path => ".",
         Depth         => 0,
         Is_Expanded   => True);

      Scan_Directory
        (Tree            => Tree,
         Parent          => Tree.Root_Id,
         Directory_Path  => To_String (Root_Full),
         Parent_Relative => ".",
         Depth           => 1);

      if Natural (Tree.Nodes.Length) >= Max_File_Tree_Nodes
        and then Length (Tree.Last_Result.Error_Text) = 0
      then
         Tree.Last_Result.Error_Text :=
           To_Unbounded_String ("file tree node limit reached");
      end if;

      Rebuild_Visible_Rows (Tree);
      Tree.Last_Result.Node_Count := Node_Count (Tree);
      return Tree;

   exception
      when Ada.Directories.Name_Error =>
         Clear (Tree);
         Tree.Last_Result.Status := File_Tree_Invalid_Root;
         Tree.Last_Result.Root_Path := To_Unbounded_String (Root_Path);
         Tree.Last_Result.Error_Text := To_Unbounded_String ("invalid root");
         return Tree;
      when Ada.Directories.Use_Error =>
         Clear (Tree);
         Tree.Last_Result.Status := File_Tree_Permission_Denied;
         Tree.Last_Result.Root_Path := To_Unbounded_String (Root_Path);
         Tree.Last_Result.Error_Text := To_Unbounded_String ("permission denied");
         return Tree;
      when others =>
         Clear (Tree);
         Tree.Last_Result.Status := File_Tree_Read_Error;
         Tree.Last_Result.Root_Path := To_Unbounded_String (Root_Path);
         Tree.Last_Result.Error_Text := To_Unbounded_String ("file tree read error");
         return Tree;
   end Scan_Project;

   function Scan_Status
     (Tree : File_Tree_State) return File_Tree_Scan_Result
   is
      Result : File_Tree_Scan_Result := Tree.Last_Result;
   begin
      Result.Node_Count := Node_Count (Tree);
      return Result;
   end Scan_Status;

end Editor.File_Tree;
