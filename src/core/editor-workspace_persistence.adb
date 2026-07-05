with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;

package body Editor.Workspace_Persistence is

   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;

   Current_Format_Version : constant Natural := 1;
   Default_File_Tree_Width : constant Natural := 28;
   Default_Bottom_Height   : constant Natural := 8;

   type Section_Id is
     (Root_Section,
      Open_Files_Section,
      Active_File_Section,
      File_Tree_Expanded_Section,
      Panels_Section,
      Continuity_Section,
      Unknown_Section);

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Natural_Text (Value : Natural) return String is
   begin
      return Trim (Natural'Image (Value));
   end Natural_Text;

   function Bool_Text (Value : Boolean) return String is
   begin
      if Value then
         return "true";
      else
         return "false";
      end if;
   end Bool_Text;

   function Content_Text (Content : Bottom_Content_Id) return String is
   begin
      case Content is
         when Workspace_Problems_Content =>
            return "problems";
         when Workspace_Search_Results_Content =>
            return "search-results";
      end case;
   end Content_Text;

   function Feature_Panel_Text
     (Feature : Workspace_Feature_Panel_Id) return String
   is
   begin
      case Feature is
         when Workspace_Outline_Feature =>
            return "outline";
         when Workspace_Messages_Feature =>
            return "messages";
         when Workspace_Search_Results_Feature =>
            return "search-results";
         when Workspace_Diagnostics_Feature =>
            return "diagnostics";
      end case;
   end Feature_Panel_Text;

   function Quick_Open_Filter_Text
     (Filter : Workspace_Quick_Open_File_Kind_Filter) return String
   is
   begin
      case Filter is
         when Workspace_Quick_Open_All_Files =>
            return "all";
         when Workspace_Quick_Open_Ada_Files =>
            return "ada";
         when Workspace_Quick_Open_Test_Files =>
            return "tests";
         when Workspace_Quick_Open_Doc_Files =>
            return "docs";
         when Workspace_Quick_Open_Other_Files =>
            return "other";
      end case;
   end Quick_Open_Filter_Text;


   function Is_Decimal_Natural_Text (Text : String) return Boolean is
   begin
      if Text'Length = 0 then
         return False;
      end if;

      for Ch of Text loop
         if Ch < '0' or else Ch > '9' then
            return False;
         end if;
      end loop;

      --  Canonical save emits Natural values with Natural'Image trimmed.
      --  That representation never contains leading zeroes except for the
      --  single value "0".  Reject padded numeric spellings so strict
      --  load does not accept a second equivalent schema form.
      if Text'Length > 1 and then Text (Text'First) = '0' then
         return False;
      end if;

      return True;
   end Is_Decimal_Natural_Text;

   function Parse_Natural_Strict
     (Text  : String;
      Value : out Natural) return Boolean
   is
   begin
      if not Is_Decimal_Natural_Text (Text) then
         Value := 0;
         return False;
      end if;

      Value := Natural'Value (Text);
      return True;
   exception
      when others =>
         Value := 0;
         return False;
   end Parse_Natural_Strict;

   function Parse_Boolean_Strict
     (Text  : String;
      Value : out Boolean) return Boolean
   is
   begin
      if Text = "true" then
         Value := True;
         return True;
      elsif Text = "false" then
         Value := False;
         return True;
      else
         Value := False;
         return False;
      end if;
   end Parse_Boolean_Strict;

   function Parse_Content_Strict
     (Text    : String;
      Content : out Bottom_Content_Id) return Boolean
   is
   begin
      if Text = "problems" then
         Content := Workspace_Problems_Content;
         return True;
      elsif Text = "search-results" then
         Content := Workspace_Search_Results_Content;
         return True;
      else
         Content := Workspace_Problems_Content;
         return False;
      end if;
   end Parse_Content_Strict;

   function Parse_Feature_Panel_Strict
     (Text    : String;
      Feature : out Workspace_Feature_Panel_Id) return Boolean
   is
   begin
      if Text = "outline" then
         Feature := Workspace_Outline_Feature;
         return True;
      elsif Text = "messages" then
         Feature := Workspace_Messages_Feature;
         return True;
      elsif Text = "search-results" then
         Feature := Workspace_Search_Results_Feature;
         return True;
      elsif Text = "diagnostics" then
         Feature := Workspace_Diagnostics_Feature;
         return True;
      else
         Feature := Workspace_Outline_Feature;
         return False;
      end if;
   end Parse_Feature_Panel_Strict;

   function Parse_Quick_Open_Filter_Strict
     (Text   : String;
      Filter : out Workspace_Quick_Open_File_Kind_Filter) return Boolean
   is
   begin
      if Text = "all" then
         Filter := Workspace_Quick_Open_All_Files;
         return True;
      elsif Text = "ada" then
         Filter := Workspace_Quick_Open_Ada_Files;
         return True;
      elsif Text = "tests" then
         Filter := Workspace_Quick_Open_Test_Files;
         return True;
      elsif Text = "docs" then
         Filter := Workspace_Quick_Open_Doc_Files;
         return True;
      elsif Text = "other" then
         Filter := Workspace_Quick_Open_Other_Files;
         return True;
      else
         Filter := Workspace_Quick_Open_All_Files;
         return False;
      end if;
   end Parse_Quick_Open_Filter_Strict;

   function Normalize_Directory_Scope
     (Scope : String;
      Valid : out Boolean) return String
   is
      Clean : constant String := Trim (Scope);
   begin
      if Clean'Length = 0 then
         Valid := True;
         return "";
      elsif Clean (Clean'Last) = '/' then
         declare
            Path : constant String :=
              (if Clean'Length = 1 then "" else Clean (Clean'First .. Clean'Last - 1));
            Normalized : constant String := Normalize_Project_Relative_Path (Path, Valid);
         begin
            if Valid then
               return Normalized & "/";
            end if;
            return "";
         end;
      else
         declare
            Normalized : constant String := Normalize_Project_Relative_Path (Clean, Valid);
         begin
            if Valid then
               return Normalized & "/";
            end if;
            return "";
         end;
      end if;
   end Normalize_Directory_Scope;

   function Value_After_Strict
     (Field : String;
      Key   : String;
      Found : out Boolean) return String
   is
      Eq : constant Natural := Ada.Strings.Fixed.Index (Field, "=");
   begin
      if Eq > 0
        and then Field (Field'First .. Eq - 1) = Key
      then
         Found := True;
         return Field (Eq + 1 .. Field'Last);
      end if;

      Found := False;
      return "";
   end Value_After_Strict;

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

   function Has_Control_Character (Path : String) return Boolean is
   begin
      for Ch of Path loop
         if Character'Pos (Ch) < 32 or else Character'Pos (Ch) = 127 then
            return True;
         end if;
      end loop;
      return False;
   end Has_Control_Character;

   function Has_Workspace_Path_Meta_Character (Path : String) return Boolean is
   begin
      for Ch of Path loop
         if Ch = '|' or else Ch = '=' or else Ch = '[' or else Ch = ']' then
            return True;
         end if;
      end loop;
      return False;
   end Has_Workspace_Path_Meta_Character;

   function Has_Backslash_Separator (Path : String) return Boolean is
   begin
      for Ch of Path loop
         if Ch = '\' then
            return True;
         end if;
      end loop;
      return False;
   end Has_Backslash_Separator;

   function Is_Absolute_Path (Path : String) return Boolean is
   begin
      if Path'Length = 0 then
         return False;
      elsif Path (Path'First) = '/' or else Path (Path'First) = '\' then
         return True;
      elsif Path'Length >= 3
        and then Path (Path'First + 1) = ':'
        and then (Path (Path'First + 2) = '/' or else Path (Path'First + 2) = '\')
      then
         return True;
      else
         return False;
      end if;
   end Is_Absolute_Path;

   function Normalize_Project_Relative_Path
     (Path  : String;
      Valid : out Boolean) return String
   is
      Clean  : constant String := Path;
      Result : Unbounded_String := Null_Unbounded_String;
      Pos    : Natural;
      Next   : Natural;

      procedure Reject is
      begin
         Valid := False;
      end Reject;
   begin
      Valid := True;
      if Clean'Length = 0
        or else Clean /= Trim (Clean)
        or else Has_Control_Character (Clean)
        or else Has_Workspace_Path_Meta_Character (Clean)
        or else Has_Backslash_Separator (Clean)
        or else Is_Absolute_Path (Clean)
        or else Clean (Clean'Last) = '/'
      then
         Reject;
         return "";
      end if;

      Pos := Clean'First;
      while Pos <= Clean'Last loop
         Next := Pos;
         while Next <= Clean'Last
           and then Clean (Next) /= '/'
         loop
            Next := Next + 1;
         end loop;

         declare
            Segment : constant String := Clean (Pos .. Next - 1);
         begin
            if Segment'Length = 0 then
               --  Canonical save never emits leading, trailing, or doubled
               --  separators inside project-relative workspace paths.  Reject
               --  these spellings instead of normalizing them into another
               --  equivalent strict-schema form.
               Reject;
               return "";
            elsif Segment = "." or else Segment = ".." then
               Reject;
               return "";
            else
               if Length (Result) > 0 then
                  Append (Result, "/");
               end if;
               Append (Result, Segment);
            end if;
         end;

         Pos := Next + 1;
      end loop;

      if Length (Result) = 0 then
         Reject;
         return "";
      end if;

      return To_String (Result);
   end Normalize_Project_Relative_Path;

   function Is_Safe_Project_Relative_Path
     (Path : String) return Boolean
   is
      Valid : Boolean;
      Ignore : constant String := Normalize_Project_Relative_Path (Path, Valid);
      pragma Unreferenced (Ignore);
   begin
      return Valid;
   end Is_Safe_Project_Relative_Path;

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

   function Has_Malformed_Metadata_Separators
     (Line      : String;
      First_Sep : Natural) return Boolean
   is
   begin
      if First_Sep = 0
        or else First_Sep = Line'Last
        or else Line (Line'Last) = '|'
      then
         return True;
      end if;

      for I in First_Sep .. Line'Last - 1 loop
         if Line (I) = '|' and then Line (I + 1) = '|' then
            return True;
         end if;
      end loop;

      return False;
   end Has_Malformed_Metadata_Separators;

   procedure Report_Unsupported_Field
     (Snapshot : in out Workspace_Snapshot;
      Status   : in out Workspace_Persistence_Status;
      Line_No  : Natural;
      Text     : String)
   is
   begin
      Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Text);
      Mark_Partial (Status);
   end Report_Unsupported_Field;

   procedure Parse_Project_Reference_Line
     (Line     : String;
      Line_No  : Natural;
      Snapshot : in out Workspace_Snapshot;
      Status   : in out Workspace_Persistence_Status)
   is
      Found : Boolean;
      Val   : constant String := Value_After_Strict (Line, "project-root", Found);
   begin
      if Found then
         if Val'Length = 0 or else Val /= Trim (Val) then
            Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
            Mark_Partial (Status);
            return;
         end if;

         Set_Project_Root (Snapshot, Val);
         if not Snapshot.Has_Root then
            Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
            Mark_Partial (Status);
         end if;
      else
         Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Line);
         Mark_Partial (Status);
      end if;
   end Parse_Project_Reference_Line;


   procedure Parse_Open_File_Line
     (Line     : String;
      Line_No  : Natural;
      Snapshot : in out Workspace_Snapshot;
      Status   : in out Workspace_Persistence_Status)
   is
      Sep   : constant Natural := Ada.Strings.Fixed.Index (Line, "|");
      Item : Workspace_File_Entry;
      Pos   : Natural;
      Next  : Natural;
      Field : Unbounded_String;
      Found : Boolean;
      N     : Natural;
      B     : Boolean;
      Saw_Relative : Boolean := False;
      Saw_Row      : Boolean := False;
      Saw_Col      : Boolean := False;
      Saw_View     : Boolean := False;
      Saw_Unsupported_Field : Boolean := False;
      Saw_Duplicate_Field   : Boolean := False;
      Field_No              : Natural := 0;
   begin
      if Sep = 0 then
         --  The current workspace schema writes open-file rows with explicit
         --  structural metadata.  A bare path is noncanonical and is rejected
         --  instead of being treated as structural input.
         if Ada.Strings.Fixed.Index (Line, "=") > 0 then
            Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Line);
         else
            Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
         end if;
         Mark_Partial (Status);
         return;
      elsif Has_Malformed_Metadata_Separators (Line, Sep) then
         Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
         Mark_Partial (Status);
         return;
      end if;

      declare
         Raw_Path_Original : constant String := Line (Line'First .. Sep - 1);
         Raw_Path          : constant String := Trim (Raw_Path_Original);
      begin
         if Raw_Path_Original /= Raw_Path then
            Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
            Mark_Partial (Status);
            return;
         elsif Ada.Strings.Fixed.Index (Raw_Path, "=") > 0 then
            Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Raw_Path);
            Mark_Partial (Status);
            return;
         end if;
         Item.Path := To_Unbounded_String (Raw_Path);
      end;

      if Length (Item.Path) = 0 then
         Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
         Mark_Partial (Status);
         return;
      end if;

      Pos := Sep + 1;
      while Pos <= Line'Last loop
         Next := Ada.Strings.Fixed.Index (Line (Pos .. Line'Last), "|");
         if Next = 0 then
            Field := To_Unbounded_String (Line (Pos .. Line'Last));
            Pos := Line'Last + 1;
         else
            Field := To_Unbounded_String (Line (Pos .. Next - 1));
            Pos := Next + 1;
         end if;

         Field_No := Field_No + 1;
         declare
            Text : constant String := To_String (Field);
            Val  : constant String := Value_After_Strict (Text, "row", Found);
         begin
            if Found then
               if Saw_Row or else Field_No /= 2 then
                  Saw_Duplicate_Field := True;
                  Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                  Mark_Partial (Status);
               elsif Parse_Natural_Strict (Val, N) then
                  Item.Cursor_Row := N;
                  Saw_Row := True;
               else
                  Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Text);
                  Mark_Partial (Status);
               end if;
            else
               declare
                  Val2 : constant String := Value_After_Strict (Text, "col", Found);
               begin
                  if Found then
                     if Saw_Col or else Field_No /= 3 then
                        Saw_Duplicate_Field := True;
                        Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                        Mark_Partial (Status);
                     elsif Parse_Natural_Strict (Val2, N) then
                        Item.Cursor_Column := N;
                        Saw_Col := True;
                     else
                        Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Text);
                        Mark_Partial (Status);
                     end if;
                  else
                     declare
                        Val3 : constant String := Value_After_Strict (Text, "view", Found);
                     begin
                        if Found then
                           if Saw_View or else Field_No /= 4 then
                              Saw_Duplicate_Field := True;
                              Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                              Mark_Partial (Status);
                           elsif Parse_Natural_Strict (Val3, N) then
                              Item.View_First_Row := N;
                              Saw_View := True;
                           else
                              Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Text);
                              Mark_Partial (Status);
                           end if;
                        else
                           declare
                              Val4 : constant String := Value_After_Strict (Text, "relative", Found);
                           begin
                              if Found then
                                 if Saw_Relative or else Field_No /= 1 then
                                    Saw_Duplicate_Field := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                                    Mark_Partial (Status);
                                 elsif Parse_Boolean_Strict (Val4, B)
                                   and then B
                                 then
                                    Item.Is_Project_Relative := True;
                                    Saw_Relative := True;
                                 else
                                    --  The current canonical workspace schema
                                    --  only persists project-relative file
                                    --  references.  relative=false is not a
                                    --  retained structural variant.
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                                    Mark_Partial (Status);
                                 end if;
                              else
                                 --  Open-file entries may only carry the
                                 --  canonical structural metadata keys.
                                 Saw_Unsupported_Field := True;
                                 Report_Unsupported_Field
                                   (Snapshot, Status, Line_No, Text);
                              end if;
                           end;
                        end if;
                     end;
                  end if;
               end;
            end if;
         end;
      end loop;

      if Saw_Unsupported_Field or else Saw_Duplicate_Field then
         Mark_Partial (Status);
         return;
      end if;

      if not (Saw_Relative and Saw_Row and Saw_Col and Saw_View) then
         Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
         Mark_Partial (Status);
         return;
      end if;

      declare
         Before : constant Natural := Open_File_Count (Snapshot);
      begin
         Add_Open_File (Snapshot, Item);
         if Open_File_Count (Snapshot) = Before then
            if Item.Is_Project_Relative
              and then Is_Safe_Project_Relative_Path (To_String (Item.Path))
            then
               Add_Diagnostic (Snapshot, Duplicate_Path, Line_No, To_String (Item.Path));
            else
               Add_Diagnostic (Snapshot, Invalid_Path, Line_No, To_String (Item.Path));
            end if;
            Mark_Partial (Status);
         end if;
      end;
   exception
      when others =>
         Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
         Mark_Partial (Status);
   end Parse_Open_File_Line;

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


   function Audit_Serialized_Buffer_Persistence
     (Serialized_Workspace : String) return Workspace_Buffer_Persistence_Audit
   is
      Result  : Workspace_Buffer_Persistence_Audit;
      Section : Section_Id := Root_Section;

      function Canonical_Field_Name (Text : String) return String is
         use Ada.Characters.Handling;
         Trimmed : constant String := Trim (Text);
         Result  : String (Trimmed'Range);
      begin
         for I in Trimmed'Range loop
            if Trimmed (I) = '_' or else Trimmed (I) = ' ' then
               Result (I) := '-';
            else
               Result (I) := To_Lower (Trimmed (I));
            end if;
         end loop;
         return Result;
      end Canonical_Field_Name;

      function Field_Name_Of (Field : String) return String is
         Eq : constant Natural := Ada.Strings.Fixed.Index (Field, "=");
      begin
         if Eq = 0 then
            return Canonical_Field_Name (Field);
         elsif Eq = Field'First then
            return "";
         else
            return Canonical_Field_Name (Field (Field'First .. Eq - 1));
         end if;
      end Field_Name_Of;

      procedure Mark_Forbidden_Field (Raw_Name : String) is
         Name : constant String := Field_Name_Of (Raw_Name);
      begin
         if Name'Length = 0 then
            return;
         end if;

         if Name = "runtime-buffer-id"
           or else Name = "buffer-runtime-id"
           or else Name = "buffer-id"
           or else Name = "row-buffer-id"
           or else Name = "payload-buffer"
           or else Name = "payload-buffer-id"
         then
            Result.Runtime_Buffer_Id_Persisted := True;
         elsif Name = "active-buffer-id"
           or else Name = "active-runtime-buffer-id"
         then
            Result.Active_Buffer_Id_Persisted := True;
         elsif Name = "selected-buffer-id"
           or else Name = "selected-runtime-buffer-id"
         then
            Result.Selected_Buffer_Id_Persisted := True;
         elsif Name = "buffer-list"
           or else Name = "buffer-list-selection"
           or else Name = "buffer-list-selected"
           or else Name = "buffer-list-filter"
           or else Name = "buffer-list-row"
           or else Name = "buffer-list-state"
           or else Name = "selected-row"
           or else Name = "selected-buffer-row"
         then
            Result.Buffer_List_State_Persisted := True;
         elsif Name = "dirty-text"
           or else Name = "modified-text"
           or else Name = "dirty-buffer-text"
         then
            Result.Dirty_Text_Persisted := True;
         elsif Name = "scratch-text"
           or else Name = "scratch-buffer-text"
         then
            Result.Scratch_Text_Persisted := True;
         elsif Name = "conflict-token"
           or else Name = "file-conflict-token"
           or else Name = "observed-file-token"
           or else Name = "observed-file-status-code"
         then
            Result.Conflict_Token_Persisted := True;
         elsif Name = "close-prompt"
           or else Name = "close-prompt-state"
           or else Name = "pending-close"
           or else Name = "pending-close-buffer-ids"
           or else Name = "dirty-close-prompt-buffer-ids"
           or else Name = "file-conflict-prompt"
           or else Name = "file-conflict-prompt-state"
         then
            Result.Close_Prompt_State_Persisted := True;
         elsif Name = "undo-stack"
           or else Name = "redo-stack"
           or else Name = "clipboard"
           or else Name = "clipboard-text"
         then
            Result.Undo_Redo_Clipboard_Persisted := True;
         end if;
      end Mark_Forbidden_Field;

      procedure Audit_Bar_Separated_Metadata
        (Line      : String;
         First_Pos : Natural)
      is
         Pos  : Natural := First_Pos;
         Next : Natural;
      begin
         if First_Pos = 0 or else First_Pos > Line'Last then
            return;
         end if;

         while Pos <= Line'Last loop
            Next := Ada.Strings.Fixed.Index (Line (Pos .. Line'Last), "|");
            if Next = 0 then
               if Ada.Strings.Fixed.Index (Line (Pos .. Line'Last), "=") > 0 then
                  Mark_Forbidden_Field (Line (Pos .. Line'Last));
               end if;
               Pos := Line'Last + 1;
            else
               if Next > Pos
                 and then Ada.Strings.Fixed.Index (Line (Pos .. Next - 1), "=") > 0
               then
                  Mark_Forbidden_Field (Line (Pos .. Next - 1));
               end if;
               Pos := Next + 1;
            end if;
         end loop;
      end Audit_Bar_Separated_Metadata;

      procedure Audit_Structural_Line (Raw_Line : String) is
         Line : constant String := Trim (Raw_Line);
         Eq   : Natural;
         Bar  : Natural;
      begin
         if Line'Length = 0 then
            return;
         end if;

         if Line (Line'First) = '[' and then Line (Line'Last) = ']' then
            declare
               Name : constant String := Canonical_Field_Name
                 (Line (Line'First + 1 .. Line'Last - 1));
            begin
               if Name = "open-files" then
                  Section := Open_Files_Section;
               elsif Name = "active-file" then
                  Section := Active_File_Section;
               elsif Name = "file-tree-expanded" then
                  Section := File_Tree_Expanded_Section;
               elsif Name = "panels" then
                  Section := Panels_Section;
               elsif Name = "continuity" then
                  Section := Continuity_Section;
               else
                  Section := Unknown_Section;
                  --  Unknown sections are not blanket failures: old/future
                  --  workspace files may carry unrelated sections.  Only
                  --  structurally named buffer-runtime sections fail here.
                  Mark_Forbidden_Field (Name);
               end if;
               return;
            end;
         end if;

         case Section is
            when Root_Section | Panels_Section | Unknown_Section =>
               Eq := Ada.Strings.Fixed.Index (Line, "=");
               if Eq > 0 and then Eq > Line'First then
                  Mark_Forbidden_Field (Line (Line'First .. Eq - 1));
               end if;

            when Continuity_Section =>
               Eq := Ada.Strings.Fixed.Index (Line, "=");
               if Eq > 0 and then Eq > Line'First then
                  Mark_Forbidden_Field (Line (Line'First .. Eq - 1));
               end if;

            when Open_Files_Section | Active_File_Section =>
               Bar := Ada.Strings.Fixed.Index (Line, "|");
               if Bar > 0 then
                  Audit_Bar_Separated_Metadata (Line, Bar + 1);
               elsif Ada.Strings.Fixed.Index (Line, "=") > 0 then
                  --  A key/value row in an open-file section is metadata, not
                  --  a path reference, so audit the field name structurally.
                  Mark_Forbidden_Field (Line);
               end if;

            when File_Tree_Expanded_Section =>
               --  Expanded paths are structural path references.  Do not scan
               --  path values for forbidden words; only explicit metadata after
               --  a separator is audited as persisted fields.
               Bar := Ada.Strings.Fixed.Index (Line, "|");
               if Bar > 0 then
                  Audit_Bar_Separated_Metadata (Line, Bar + 1);
               end if;
         end case;
      end Audit_Structural_Line;

      Pos : Natural := Serialized_Workspace'First;
      LF  : Natural;
   begin
      while Pos <= Serialized_Workspace'Last loop
         LF := Ada.Strings.Fixed.Index
           (Serialized_Workspace (Pos .. Serialized_Workspace'Last),
            (1 => Character'Val (10)));
         if LF = 0 then
            Audit_Structural_Line
              (Serialized_Workspace (Pos .. Serialized_Workspace'Last));
            Pos := Serialized_Workspace'Last + 1;
         else
            Audit_Structural_Line (Serialized_Workspace (Pos .. LF - 1));
            Pos := LF + 1;
         end if;
      end loop;

      Result.Safe :=
        not Result.Runtime_Buffer_Id_Persisted
        and then not Result.Active_Buffer_Id_Persisted
        and then not Result.Selected_Buffer_Id_Persisted
        and then not Result.Buffer_List_State_Persisted
        and then not Result.Dirty_Text_Persisted
        and then not Result.Scratch_Text_Persisted
        and then not Result.Conflict_Token_Persisted
        and then not Result.Close_Prompt_State_Persisted
        and then not Result.Undo_Redo_Clipboard_Persisted;

      return Result;
   end Audit_Serialized_Buffer_Persistence;


   function Audit_Buffer_Persistence
     (Snapshot : Workspace_Snapshot) return Workspace_Buffer_Persistence_Audit
   is
   begin
      return Audit_Serialized_Buffer_Persistence (Serialized_Text (Snapshot));
   end Audit_Buffer_Persistence;

   function Restore_Details_Label
     (Summary : Workspace_Restore_Summary) return String
   is
   begin
      return "restore details: files " & Natural_Text (Summary.Files_Restored)
        & "/" & Natural_Text (Summary.Files_Requested)
        & ", skipped files " & Natural_Text (Summary.Files_Skipped)
        & ", expanded paths " & Natural_Text (Summary.Expansions_Restored)
        & "/" & Natural_Text (Summary.Expansions_Requested)
        & ", skipped expanded paths " & Natural_Text (Summary.Expansions_Skipped)
        & ", clamped panels " & Natural_Text (Summary.Panel_Values_Clamped);
   end Restore_Details_Label;

   function Audit_Restore_Roundtrip
     (Before  : Workspace_Snapshot;
      After   : Workspace_Snapshot;
      Summary : Workspace_Restore_Summary) return Workspace_Restore_Audit
   is
      Normalized_Before : Workspace_Snapshot := Before;
      Normalized_After  : Workspace_Snapshot := After;
      Buffer_Audit      : Workspace_Buffer_Persistence_Audit;
      Result            : Workspace_Restore_Audit;
   begin
      Normalize (Normalized_Before);
      Normalize (Normalized_After);
      Buffer_Audit := Audit_Buffer_Persistence (Normalized_After);

      Result.Snapshots_Equivalent := Equivalent (Normalized_Before, Normalized_After);
      Result.Runtime_State_Excluded := Buffer_Audit.Safe;
      Result.Restore_Counts_Coherent :=
        Summary.Files_Restored <= Summary.Files_Requested
        and then Summary.Files_Skipped <= Summary.Files_Requested
        and then Summary.Files_Restored + Summary.Files_Skipped =
          Summary.Files_Requested
        and then Summary.Expansions_Restored <= Summary.Expansions_Requested
        and then Summary.Expansions_Skipped <= Summary.Expansions_Requested
        and then Summary.Expansions_Restored + Summary.Expansions_Skipped =
          Summary.Expansions_Requested;
      Result.Continuity_State_Restored :=
        Normalized_Before.Has_Recent_Project = Normalized_After.Has_Recent_Project
        and then To_String (Normalized_Before.Recent_Project) =
          To_String (Normalized_After.Recent_Project)
        and then To_String (Normalized_Before.Quick_Open_Scope) =
          To_String (Normalized_After.Quick_Open_Scope)
        and then Normalized_Before.Quick_Open_Filter =
          Normalized_After.Quick_Open_Filter
        and then Normalized_Before.Feature_Panel_Visible =
          Normalized_After.Feature_Panel_Visible
        and then Normalized_Before.Active_Feature_Panel =
          Normalized_After.Active_Feature_Panel;
      Result.Safe := Result.Snapshots_Equivalent
        and then Result.Runtime_State_Excluded
        and then Result.Restore_Counts_Coherent
        and then Result.Continuity_State_Restored;
      return Result;
   end Audit_Restore_Roundtrip;


   function Session_File_Path
     (Project_Root : String) return String
   is
   begin
      return Ada.Directories.Compose
        (Ada.Directories.Compose (Project_Root, ".editor"), "session");
   end Session_File_Path;


   function Session_File_Status
     (Project_Root : String) return Workspace_Session_File_Status
   is
      Path : constant String := Session_File_Path (Project_Root);
      File : Ada.Text_IO.File_Type;
   begin
      if Project_Root'Length = 0 or else not Ada.Directories.Exists (Path) then
         return Session_File_Missing;
      end if;

      if Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File then
         return Session_File_Unreadable;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      Ada.Text_IO.Close (File);
      return Session_File_Present;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return Session_File_Unreadable;
   end Session_File_Status;

   function Workspace_State_Exists
     (Project_Root : String) return Boolean
   is
   begin
      return Session_File_Status (Project_Root) = Session_File_Present;
   end Workspace_State_Exists;

   function Comparable_Path (Path : String) return String is
      Stripped : constant String := Trim (Path);
      Result   : String (Stripped'Range);
   begin
      if Stripped'Length = 0 then
         return "";
      end if;

      for I in Stripped'Range loop
         if Stripped (I) = '\' then
            Result (I) := '/';
         else
            Result (I) := Stripped (I);
         end if;
      end loop;

      return Result;
   end Comparable_Path;

   function Is_Session_File_Path_For_Project
     (Project_Root : String;
      Path         : String) return Boolean
   is
   begin
      return Comparable_Path (Path) = Comparable_Path (Session_File_Path (Project_Root));
   exception
      when others =>
         return False;
   end Is_Session_File_Path_For_Project;

   procedure Write_Snapshot_To_File
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status)
   is
      File : Ada.Text_IO.File_Type;
      Copy : Workspace_Snapshot := Snapshot;
   begin
      Status := Workspace_Persistence_Ok;
      Normalize (Copy);

      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Serialized_Text (Copy));
      --  Settings-owned data, including the active theme, is intentionally
      --  excluded from the workspace session format.  Workspace persistence
      --  records structural session state only.
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Status := Workspace_Persistence_Write_Error;
   end Write_Snapshot_To_File;

   procedure Save_To_File
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status)
   is
   begin
      Save_To_File_Atomically (Snapshot, Path, Status);
   end Save_To_File;

   procedure Save_To_File_Atomically
     (Snapshot : Workspace_Snapshot;
      Path     : String;
      Status   : out Workspace_Persistence_Status)
   is
      Dir      : constant String := Ada.Directories.Containing_Directory (Path);
      Base     : constant String := Ada.Directories.Simple_Name (Path);
      Temp     : constant String := Ada.Directories.Compose
        (Dir, "." & Base & ".tmp");

      procedure Remove_Temp_Best_Effort is
      begin
         if Ada.Directories.Exists (Temp) then
            Ada.Directories.Delete_File (Temp);
         end if;
      exception
         when others =>
            null;
      end Remove_Temp_Best_Effort;
   begin
      Status := Workspace_Persistence_Ok;
      if Dir'Length > 0 and then not Ada.Directories.Exists (Dir) then
         Ada.Directories.Create_Path (Dir);
      end if;

      Remove_Temp_Best_Effort;
      Write_Snapshot_To_File (Snapshot, Temp, Status);
      if Status /= Workspace_Persistence_Ok then
         Remove_Temp_Best_Effort;
         return;
      end if;

      declare
         Success : Boolean := False;
      begin
         GNAT.OS_Lib.Rename_File (Temp, Path, Success);
         if not Success then
            Remove_Temp_Best_Effort;
            Status := Workspace_Persistence_Write_Error;
            return;
         end if;
      exception
         when others =>
            Remove_Temp_Best_Effort;
            Status := Workspace_Persistence_Write_Error;
            return;
      end;

      Remove_Temp_Best_Effort;
      Status := Workspace_Persistence_Ok;
   exception
      when others =>
         Status := Workspace_Persistence_Write_Error;
   end Save_To_File_Atomically;

   procedure Load_From_File
     (Path     : String;
      Snapshot : out Workspace_Snapshot;
      Status   : out Workspace_Persistence_Status)
   is
      File    : Ada.Text_IO.File_Type;
      Line_No : Natural := 0;
      Section : Section_Id := Root_Section;
      Header  : Boolean := False;
      Partial : Workspace_Persistence_Status := Workspace_Persistence_Ok;
      Project_Root_Seen    : Boolean := False;
      Project_Root_Row_Seen : Boolean := False;
      Last_Section_Rank    : Natural := 0;
      Open_Section_Seen    : Boolean := False;
      Active_Section_Seen  : Boolean := False;
      Active_File_Row_Seen : Boolean := False;
      Expanded_Section_Seen : Boolean := False;
      Panels_Seen          : Boolean := False;
      Continuity_Seen      : Boolean := False;
      Panel_File_Tree_Seen : Boolean := False;
      Panel_Width_Seen     : Boolean := False;
      Panel_Bottom_Seen    : Boolean := False;
      Panel_Height_Seen    : Boolean := False;
      Panel_Content_Seen   : Boolean := False;
      Panel_Invalid        : Boolean := False;
      Panel_Field_No       : Natural := 0;
      Panel_File_Tree_Visible_Value : Boolean := True;
      Panel_File_Tree_Width_Value   : Natural := Default_File_Tree_Width;
      Panel_Bottom_Visible_Value    : Boolean := False;
      Panel_Bottom_Height_Value     : Natural := Default_Bottom_Height;
      Panel_Bottom_Content_Value    : Bottom_Content_Id := Workspace_Problems_Content;
      Continuity_Recent_Seen        : Boolean := False;
      Continuity_Quick_Open_Seen    : Boolean := False;
      Continuity_Quick_Filter_Seen  : Boolean := False;
      Continuity_Feature_Visible_Seen : Boolean := False;
      Continuity_Active_Feature_Seen  : Boolean := False;
      Continuity_Invalid            : Boolean := False;
      Continuity_Field_No           : Natural := 0;
      Continuity_Has_Recent_Value   : Boolean := False;
      Continuity_Recent_Value       : Unbounded_String := Null_Unbounded_String;
      Continuity_Quick_Open_Value   : Unbounded_String := Null_Unbounded_String;
      Continuity_Quick_Filter_Value : Workspace_Quick_Open_File_Kind_Filter :=
        Workspace_Quick_Open_All_Files;
      Continuity_Feature_Visible_Value : Boolean := False;
      Continuity_Active_Feature_Value  : Workspace_Feature_Panel_Id :=
        Workspace_Outline_Feature;
      Last_Expanded_Path            : Unbounded_String := Null_Unbounded_String;
   begin
      Clear (Snapshot);
      Status := Workspace_Persistence_Ok;

      if not Ada.Directories.Exists (Path) then
         Status := Workspace_Persistence_Not_Found;
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Raw_Line : constant String := Ada.Text_IO.Get_Line (File);
            Line     : constant String := Trim (Raw_Line);
         begin
            Line_No := Line_No + 1;
            if Line'Length = 0 then
               --  Canonical workspace save emits no blank rows.  Before the
               --  version header, any row is a format error because the header
               --  must be the first physical line of the strict schema.
               Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Raw_Line);
               if not Header then
                  Ada.Text_IO.Close (File);
                  Status := Workspace_Persistence_Invalid_Format;
                  return;
               end if;
               Mark_Partial (Partial);
            elsif Raw_Line /= Line then
               --  The current workspace schema is emitted in a canonical
               --  whitespace-free text form.  Do not trim padded rows into
               --  valid structural state; before the header this invalidates
               --  the whole file rather than allowing later repair.
               Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Raw_Line);
               if not Header then
                  Ada.Text_IO.Close (File);
                  Status := Workspace_Persistence_Invalid_Format;
                  return;
               end if;
               Mark_Partial (Partial);
            elsif Line (Line'First) = '[' and then Line (Line'Last) = ']' then
               if not Header then
                  Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                  Ada.Text_IO.Close (File);
                  Status := Workspace_Persistence_Invalid_Format;
                  return;
               end if;
               declare
                  Name      : constant String := Line (Line'First + 1 .. Line'Last - 1);
                  Rank      : Natural := 0;
                  Duplicate : Boolean := False;
                  Target    : Section_Id := Unknown_Section;
               begin
                  if Name = "open-files" then
                     Rank := 1;
                     Duplicate := Open_Section_Seen;
                     Target := Open_Files_Section;
                  elsif Name = "active-file" then
                     Rank := 2;
                     Duplicate := Active_Section_Seen;
                     Target := Active_File_Section;
                  elsif Name = "file-tree-expanded" then
                     Rank := 3;
                     Duplicate := Expanded_Section_Seen;
                     Target := File_Tree_Expanded_Section;
                  elsif Name = "panels" then
                     Rank := 4;
                     Duplicate := Panels_Seen;
                     Target := Panels_Section;
                  elsif Name = "continuity" then
                     Rank := 5;
                     Duplicate := Continuity_Seen;
                     Target := Continuity_Section;
                  else
                     Section := Unknown_Section;
                     Add_Diagnostic (Snapshot, Unknown_Section, Line_No, Name);
                     Mark_Partial (Partial);
                  end if;

                  if Rank > 0 then
                     if Duplicate or else Rank <= Last_Section_Rank then
                        Section := Unknown_Section;
                        Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                        Mark_Partial (Partial);
                     else
                        Section := Target;
                        Last_Section_Rank := Rank;
                        case Target is
                           when Open_Files_Section =>
                              Open_Section_Seen := True;
                           when Active_File_Section =>
                              Active_Section_Seen := True;
                           when File_Tree_Expanded_Section =>
                              Expanded_Section_Seen := True;
                           when Panels_Section =>
                              Panels_Seen := True;
                           when Continuity_Section =>
                              Continuity_Seen := True;
                           when others =>
                              null;
                        end case;
                     end if;
                  end if;
               end;
            elsif not Header then
               declare
                  Prefix : constant String := "editor-workspace-version=";
                  N      : Natural;
               begin
                  if Line'Length < Prefix'Length
                    or else Line (Line'First .. Line'First + Prefix'Length - 1) /= Prefix
                  then
                     Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                     Ada.Text_IO.Close (File);
                     Status := Workspace_Persistence_Invalid_Format;
                     return;
                  end if;
                  if not Parse_Natural_Strict (Line (Line'First + Prefix'Length .. Line'Last), N) then
                     Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Line);
                     Ada.Text_IO.Close (File);
                     Status := Workspace_Persistence_Invalid_Format;
                     return;
                  elsif N /= Current_Format_Version then
                     Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                     Ada.Text_IO.Close (File);
                     Status := Workspace_Persistence_Unsupported_Version;
                     return;
                  end if;
                  Snapshot.Format_Version := N;
                  Header := True;
               end;
            else
               case Section is
                  when Root_Section =>
                     declare
                        Found : Boolean;
                        Val   : constant String := Value_After_Strict
                          (Line, "project-root", Found);
                        pragma Unreferenced (Val);
                     begin
                        if Project_Root_Row_Seen then
                           --  The strict canonical root area allows at most
                           --  one structural row.  A malformed/unsupported
                           --  first root row consumes the slot; a later
                           --  project-root row must not repair it.
                           Add_Diagnostic
                             (Snapshot, Malformed_Line, Line_No, Line);
                           Mark_Partial (Partial);
                        else
                           Project_Root_Row_Seen := True;
                           Parse_Project_Reference_Line
                             (Line, Line_No, Snapshot, Partial);
                           if Found and then Snapshot.Has_Root then
                              Project_Root_Seen := True;
                           end if;
                        end if;
                     end;
                  when Open_Files_Section =>
                     Parse_Open_File_Line (Line, Line_No, Snapshot, Partial);
                  when Active_File_Section =>
                     if Active_File_Row_Seen then
                        Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                        Mark_Partial (Partial);
                     else
                        Active_File_Row_Seen := True;
                        declare
                           Sep : constant Natural := Ada.Strings.Fixed.Index (Line, "|");
                           Rel : Boolean := True;
                        Saw_Relative : Boolean := False;
                        Saw_Unsupported_Field : Boolean := False;
                        Saw_Duplicate_Field : Boolean := False;
                        Field_No : Natural := 0;

                        procedure Apply_Active_Path (Raw_Path : String) is
                           Candidate : constant String := Trim (Raw_Path);
                        begin
                           if Raw_Path /= Candidate then
                              Add_Diagnostic
                                (Snapshot, Malformed_Line, Line_No, Raw_Path);
                              Mark_Partial (Partial);
                              return;
                           end if;

                           Set_Active_File_Path (Snapshot, Candidate, Rel);
                           if not Snapshot.Has_Active then
                              Add_Diagnostic
                                (Snapshot, Invalid_Path, Line_No, Raw_Path);
                              Mark_Partial (Partial);
                           end if;
                        end Apply_Active_Path;
                     begin
                        if Sep = 0 then
                           --  The current workspace schema writes active-file
                           --  rows with explicit relative metadata.  Do not
                           --  accept path-only noncanonical rows here.
                           if Ada.Strings.Fixed.Index (Line, "=") > 0 then
                              Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Line);
                           else
                              Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                           end if;
                           Mark_Partial (Partial);
                        elsif Has_Malformed_Metadata_Separators (Line, Sep) then
                           Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                           Mark_Partial (Partial);
                        else
                           declare
                              Pos   : Natural := Sep + 1;
                              Next  : Natural;
                              Field : Unbounded_String;
                              Found : Boolean;
                              B     : Boolean;
                           begin
                              while Pos <= Line'Last loop
                                 Next := Ada.Strings.Fixed.Index (Line (Pos .. Line'Last), "|");
                                 if Next = 0 then
                                    Field := To_Unbounded_String (Line (Pos .. Line'Last));
                                    Pos := Line'Last + 1;
                                 else
                                    Field := To_Unbounded_String (Line (Pos .. Next - 1));
                                    Pos := Next + 1;
                                 end if;

                                 Field_No := Field_No + 1;
                                 declare
                                    Text : constant String := To_String (Field);
                                    Val  : constant String := Value_After_Strict (Text, "relative", Found);
                                 begin
                                    if Found then
                                       if Saw_Relative or else Field_No /= 1 then
                                          Saw_Duplicate_Field := True;
                                          Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                                          Mark_Partial (Partial);
                                       elsif Parse_Boolean_Strict (Val, B)
                                         and then B
                                       then
                                          Rel := True;
                                          Saw_Relative := True;
                                       else
                                          --  Active-file restore is restricted
                                          --  to the same project-relative
                                          --  canonical path form used for
                                          --  open-file rows.
                                          Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Text);
                                          Mark_Partial (Partial);
                                       end if;
                                    else
                                       --  Active-file state may only carry the
                                       --  structural relative flag.
                                       Saw_Unsupported_Field := True;
                                       Report_Unsupported_Field
                                         (Snapshot, Partial, Line_No, Text);
                                    end if;
                                 end;
                              end loop;
                           end;
                           if Saw_Relative
                             and then not Saw_Unsupported_Field
                             and then not Saw_Duplicate_Field
                           then
                              Apply_Active_Path (Line (Line'First .. Sep - 1));
                           else
                              Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                              Mark_Partial (Partial);
                           end if;
                        end if;
                        exception
                           when others =>
                              Mark_Partial (Partial);
                        end;
                     end if;
                  when File_Tree_Expanded_Section =>
                     declare
                        Before : constant Natural := Expanded_File_Tree_Path_Count (Snapshot);
                        Valid  : Boolean := False;
                        Clean  : constant String := Normalize_Project_Relative_Path
                          (Line, Valid);
                     begin
                        if Ada.Strings.Fixed.Index (Line, "=") > 0 then
                           Add_Diagnostic (Snapshot, Unsupported_Key, Line_No, Line);
                           Mark_Partial (Partial);
                        elsif not Valid then
                           Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
                           Mark_Partial (Partial);
                        elsif Length (Last_Expanded_Path) > 0
                          and then Clean <= To_String (Last_Expanded_Path)
                        then
                           --  Save normalizes expanded directory paths into
                           --  deterministic ascending order.  Reject equal or
                           --  descending rows so load does not accept another
                           --  canonical spelling after current-name resolution
                           --  have been removed.
                           if Clean = To_String (Last_Expanded_Path) then
                              Add_Diagnostic
                                (Snapshot, Duplicate_Path, Line_No, Line);
                           else
                              Add_Diagnostic
                                (Snapshot, Malformed_Line, Line_No, Line);
                           end if;
                           Mark_Partial (Partial);
                        else
                           Add_Expanded_File_Tree_Path (Snapshot, Clean);
                           if Expanded_File_Tree_Path_Count (Snapshot) = Before then
                              Add_Diagnostic
                                (Snapshot, Duplicate_Path, Line_No, Line);
                              Mark_Partial (Partial);
                           else
                              Last_Expanded_Path := To_Unbounded_String (Clean);
                           end if;
                        end if;
                     end;
                  when Panels_Section =>
                     declare
                        Eq : constant Natural := Ada.Strings.Fixed.Index (Line, "=");
                        B  : Boolean;
                        N  : Natural;
                        C  : Bottom_Content_Id;
                     begin
                        Panel_Field_No := Panel_Field_No + 1;
                        if Eq = 0 then
                           Panel_Invalid := True;
                           Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                           Mark_Partial (Partial);
                        else
                           declare
                              Key : constant String := Line (Line'First .. Eq - 1);
                              Val : constant String := Line (Eq + 1 .. Line'Last);
                           begin
                              if Key = "file-tree-visible" then
                                 if Panel_File_Tree_Seen or else Panel_Field_No /= 1 then
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Boolean_Strict (Val, B) then
                                    Panel_File_Tree_Visible_Value := B;
                                    Panel_File_Tree_Seen := True;
                                 else
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "file-tree-width" then
                                 if Panel_Width_Seen or else Panel_Field_No /= 2 then
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Natural_Strict (Val, N) then
                                    if N = 0 then
                                       Panel_Invalid := True;
                                       Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                       Mark_Partial (Partial);
                                    else
                                       Panel_File_Tree_Width_Value := N;
                                       Panel_Width_Seen := True;
                                    end if;
                                 else
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "bottom-visible" then
                                 if Panel_Bottom_Seen or else Panel_Field_No /= 3 then
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Boolean_Strict (Val, B) then
                                    Panel_Bottom_Visible_Value := B;
                                    Panel_Bottom_Seen := True;
                                 else
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "bottom-height" then
                                 if Panel_Height_Seen or else Panel_Field_No /= 4 then
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Natural_Strict (Val, N) then
                                    if N = 0 then
                                       Panel_Invalid := True;
                                       Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                       Mark_Partial (Partial);
                                    else
                                       Panel_Bottom_Height_Value := N;
                                       Panel_Height_Seen := True;
                                    end if;
                                 else
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Number, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "bottom-content" then
                                 if Panel_Content_Seen or else Panel_Field_No /= 5 then
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Content_Strict (Val, C) then
                                    Panel_Bottom_Content_Value := C;
                                    Panel_Content_Seen := True;
                                 else
                                    Panel_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              else
                                 Panel_Invalid := True;
                                 Add_Diagnostic
                                   (Snapshot, Unsupported_Key, Line_No, Line);
                                 Mark_Partial (Partial);
                              end if;
                           end;
                        end if;
                     exception
                        when others =>
                           Panel_Invalid := True;
                           Mark_Partial (Partial);
                     end;
                  when Continuity_Section =>
                     declare
                        Eq : constant Natural := Ada.Strings.Fixed.Index (Line, "=");
                        B  : Boolean;
                        F  : Workspace_Feature_Panel_Id;
                        QF : Workspace_Quick_Open_File_Kind_Filter;
                        Valid : Boolean := False;
                     begin
                        Continuity_Field_No := Continuity_Field_No + 1;
                        if Eq = 0 then
                           Continuity_Invalid := True;
                           Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                           Mark_Partial (Partial);
                        else
                           declare
                              Key : constant String := Line (Line'First .. Eq - 1);
                              Val : constant String := Line (Eq + 1 .. Line'Last);
                           begin
                              if Key = "recent-project" then
                                 if Continuity_Recent_Seen or else Continuity_Field_No /= 1 then
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Val'Length = 0 then
                                    Continuity_Has_Recent_Value := False;
                                    Continuity_Recent_Value := Null_Unbounded_String;
                                    Continuity_Recent_Seen := True;
                                 elsif Val = Trim (Val)
                                   and then not Has_Control_Character (Val)
                                 then
                                    Continuity_Has_Recent_Value := True;
                                    Continuity_Recent_Value := To_Unbounded_String (Val);
                                    Continuity_Recent_Seen := True;
                                 else
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "quick-open-scope" then
                                 if Continuity_Quick_Open_Seen or else Continuity_Field_No /= 2 then
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 else
                                    declare
                                       Scope : constant String :=
                                         Normalize_Directory_Scope (Val, Valid);
                                    begin
                                       if Valid then
                                          Continuity_Quick_Open_Value :=
                                            To_Unbounded_String (Scope);
                                          Continuity_Quick_Open_Seen := True;
                                       else
                                          Continuity_Invalid := True;
                                          Add_Diagnostic (Snapshot, Invalid_Path, Line_No, Line);
                                          Mark_Partial (Partial);
                                       end if;
                                    end;
                                 end if;
                              elsif Key = "quick-open-filter" then
                                 if Continuity_Quick_Filter_Seen
                                   or else Continuity_Field_No /= 3
                                 then
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Quick_Open_Filter_Strict (Val, QF) then
                                    Continuity_Quick_Filter_Value := QF;
                                    Continuity_Quick_Filter_Seen := True;
                                 else
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "feature-panel-visible" then
                                 if Continuity_Feature_Visible_Seen
                                   or else Continuity_Field_No /= 4
                                 then
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Boolean_Strict (Val, B) then
                                    Continuity_Feature_Visible_Value := B;
                                    Continuity_Feature_Visible_Seen := True;
                                 else
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              elsif Key = "active-feature-panel" then
                                 if Continuity_Active_Feature_Seen
                                   or else Continuity_Field_No /= 5
                                 then
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Malformed_Line, Line_No, Line);
                                    Mark_Partial (Partial);
                                 elsif Parse_Feature_Panel_Strict (Val, F) then
                                    Continuity_Active_Feature_Value := F;
                                    Continuity_Active_Feature_Seen := True;
                                 else
                                    Continuity_Invalid := True;
                                    Add_Diagnostic (Snapshot, Invalid_Panel_Value, Line_No, Line);
                                    Mark_Partial (Partial);
                                 end if;
                              else
                                 Continuity_Invalid := True;
                                 Add_Diagnostic
                                   (Snapshot, Unsupported_Key, Line_No, Line);
                                 Mark_Partial (Partial);
                              end if;
                           end;
                        end if;
                     exception
                        when others =>
                           Continuity_Invalid := True;
                           Mark_Partial (Partial);
                     end;
                  when Unknown_Section =>
                     Add_Diagnostic (Snapshot, Unknown_Section, Line_No, Line);
                     Mark_Partial (Partial);
               end case;
            end if;
         end;
      end loop;

      Ada.Text_IO.Close (File);

      if Header then
         if not Open_Section_Seen then
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "missing canonical [open-files] section");
            Mark_Partial (Partial);
         end if;
         if not Active_Section_Seen then
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "missing canonical [active-file] section");
            Mark_Partial (Partial);
         end if;
         if not Expanded_Section_Seen then
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "missing canonical [file-tree-expanded] section");
            Mark_Partial (Partial);
         end if;
         if not Panels_Seen then
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "missing canonical [panels] section");
            Mark_Partial (Partial);
         end if;
      end if;

      if Panels_Seen then
         if Panel_Invalid
           or else not Panel_File_Tree_Seen
           or else not Panel_Width_Seen
           or else not Panel_Bottom_Seen
           or else not Panel_Height_Seen
           or else not Panel_Content_Seen
         then
            --  Panel layout is one canonical structural record.  Do not
            --  partially restore file-tree/bottom-panel values from a
            --  malformed or incomplete [panels] section.
            Snapshot.File_Tree_Visible := True;
            Snapshot.File_Tree_Width := Default_File_Tree_Width;
            Snapshot.Bottom_Visible := False;
            Snapshot.Bottom_Height := Default_Bottom_Height;
            Snapshot.Bottom_Content := Workspace_Problems_Content;
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "panels section is not in canonical order or is incomplete");
            Mark_Partial (Partial);
         else
            Snapshot.File_Tree_Visible := Panel_File_Tree_Visible_Value;
            Snapshot.File_Tree_Width := Panel_File_Tree_Width_Value;
            Snapshot.Bottom_Visible := Panel_Bottom_Visible_Value;
            Snapshot.Bottom_Height := Panel_Bottom_Height_Value;
            Snapshot.Bottom_Content := Panel_Bottom_Content_Value;
         end if;
      end if;

      if Continuity_Seen then
         if Continuity_Invalid
           or else not Continuity_Recent_Seen
           or else not Continuity_Quick_Open_Seen
           or else not Continuity_Quick_Filter_Seen
           or else not Continuity_Feature_Visible_Seen
           or else not Continuity_Active_Feature_Seen
         then
            Snapshot.Has_Recent_Project := False;
            Snapshot.Recent_Project := Null_Unbounded_String;
            Snapshot.Quick_Open_Scope := Null_Unbounded_String;
            Snapshot.Quick_Open_Filter := Workspace_Quick_Open_All_Files;
            Snapshot.Feature_Panel_Visible := False;
            Snapshot.Active_Feature_Panel := Workspace_Outline_Feature;
            Add_Diagnostic
              (Snapshot, Malformed_Line, 0,
               "continuity section is not in canonical order or is incomplete");
            Mark_Partial (Partial);
         else
            Snapshot.Has_Recent_Project := Continuity_Has_Recent_Value;
            Snapshot.Recent_Project :=
              (if Continuity_Has_Recent_Value
               then Continuity_Recent_Value
               else Null_Unbounded_String);
            Snapshot.Quick_Open_Scope := Continuity_Quick_Open_Value;
            Snapshot.Quick_Open_Filter := Continuity_Quick_Filter_Value;
            Snapshot.Feature_Panel_Visible := Continuity_Feature_Visible_Value;
            Snapshot.Active_Feature_Panel := Continuity_Active_Feature_Value;
         end if;
      end if;

      if Header
        and then Snapshot.Has_Active
        and then not Has_Open_File_Path (Snapshot, To_String (Snapshot.Active_Path))
      then
         Add_Diagnostic
           (Snapshot, Invalid_Path, 0,
            "active file is not present in open-files");
         Snapshot.Has_Active := False;
         Snapshot.Active_Path := Null_Unbounded_String;
         Snapshot.Active_Rel := True;
         Mark_Partial (Partial);
      end if;

      if not Header then
         Add_Diagnostic (Snapshot, Malformed_Line, 0, "missing workspace version header");
         Status := Workspace_Persistence_Invalid_Format;
      elsif Partial = Workspace_Persistence_Partial_Restore then
         Status := Workspace_Persistence_Partial_Restore;
      else
         Status := Workspace_Persistence_Ok;
      end if;
   exception
      when Ada.Text_IO.Name_Error =>
         Status := Workspace_Persistence_Not_Found;
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Status := Workspace_Persistence_Read_Error;
   end Load_From_File;

end Editor.Workspace_Persistence;
