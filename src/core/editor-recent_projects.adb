with Ada.Containers;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Editor.Recent_Projects is

   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;
   Config_Directory_Override : Unbounded_String := Null_Unbounded_String;
   Last_Ignored_Load_Entries : Natural := 0;

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

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

   function Slashed (Path : String) return String is
      Result : String (Path'Range);
   begin
      for I in Path'Range loop
         if Path (I) = '\' then
            Result (I) := '/';
         else
            Result (I) := Path (I);
         end if;
      end loop;
      return Result;
   end Slashed;

   function Normalized_Root_Path
     (Root_Path : String) return String
   is
      Clean : constant String := Strip_Trailing_Separators (Trimmed (Root_Path));
   begin
      if Clean'Length = 0 then
         return "";
      elsif Ada.Directories.Exists (Clean) then
         return Slashed (Strip_Trailing_Separators (Ada.Directories.Full_Name (Clean)));
      else
         return Slashed (Clean);
      end if;
   exception
      when others =>
         return Slashed (Clean);
   end Normalized_Root_Path;

   function Contains_Format_Separator (Text : String) return Boolean is
   begin
      for Ch of Text loop
         if Ch = '|' or else Ch = ASCII.LF or else Ch = ASCII.CR then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Format_Separator;

   function Sanitized_Field (Text : String) return String is
      T : constant String := Trimmed (Text);
   begin
      if Contains_Format_Separator (T) then
         declare
            R : String := T;
         begin
            for I in R'Range loop
               if R (I) = '|' or else R (I) = ASCII.LF or else R (I) = ASCII.CR then
                  R (I) := ' ';
               end if;
            end loop;
            return Trimmed (R);
         end;
      end if;
      return T;
   end Sanitized_Field;

   function Valid_Project_Reference_Field (Root_Path : String) return Boolean is
      Root : constant String := Trimmed (Root_Path);
   begin
      --  The recent-projects file is deliberately line-oriented and
      --  pipe-delimited.  Project references that cannot be represented in
      --  that lightweight format are unsupported recent entries and are
      --  ignored rather than being escaped into a richer persistence schema.
      return Root'Length > 0 and then not Contains_Format_Separator (Root);
   end Valid_Project_Reference_Field;

   function Existing_Project_Root (Root_Path : String) return Boolean is
   begin
      return Root_Path'Length > 0
        and then Ada.Directories.Exists (Root_Path)
        and then Ada.Directories.Kind (Root_Path) = Ada.Directories.Directory;
   exception
      when others =>
         return False;
   end Existing_Project_Root;

   function Is_Available
     (Item : Recent_Project_Entry) return Boolean
   is
   begin
      return not Item.Is_Unavailable;
   end Is_Available;

   function Path_Label
     (Item : Recent_Project_Entry) return String
   is
   begin
      return To_String (Item.Root_Path);
   end Path_Label;

   function Last_Opened_Label
     (Item : Recent_Project_Entry) return String
   is
   begin
      if Item.Last_Opened_Ms = 0 then
         return "last opened unknown";
      end if;
      return "last opened " & Trimmed (Natural'Image (Item.Last_Opened_Ms));
   end Last_Opened_Label;

   function Unavailable_Label
     (Item : Recent_Project_Entry) return String
   is
   begin
      if Item.Is_Unavailable then
         return "project path no longer exists";
      end if;
      return "";
   end Unavailable_Label;

   function Row_Label
     (Item        : Recent_Project_Entry;
      Is_Selected : Boolean := False) return String
   is
      Prefix : constant String := (if Is_Selected then "> " else "  ");
      Status : constant String :=
        (if Is_Available (Item) then Last_Opened_Label (Item)
         else Unavailable_Label (Item));
   begin
      return Prefix & To_String (Item.Display_Name)
        & " — " & Path_Label (Item)
        & (if Status'Length > 0 then " — " & Status else "");
   end Row_Label;

   function Last_Load_Ignored_Count return Natural is
   begin
      return Last_Ignored_Load_Entries;
   end Last_Load_Ignored_Count;

   function Count
     (List : Recent_Project_List) return Natural
   is
   begin
      return Natural (List.Entries.Length);
   end Count;

   function Available_Count
     (List : Recent_Project_List) return Natural
   is
      Result : Natural := 0;
   begin
      if List.Entries.Is_Empty then
         return 0;
      end if;

      for Item of List.Entries loop
         if Is_Available (Item) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Available_Count;

   function Unavailable_Count
     (List : Recent_Project_List) return Natural
   is
   begin
      return Count (List) - Available_Count (List);
   end Unavailable_Count;

   function Item
     (List  : Recent_Project_List;
      Index : Positive) return Recent_Project_Entry
   is
   begin
      return List.Entries (Natural (Index - 1));
   end Item;

   procedure Clear
     (List : in out Recent_Project_List)
   is
   begin
      List.Entries.Clear;
   end Clear;

   procedure Normalize
     (List   : in out Recent_Project_List;
      Config : Recent_Project_Config := Default_Config)
   is
      Result : Entry_Vectors.Vector;
      Root   : Unbounded_String;
   begin
      --  Normalize into a lightweight, deduplicated set.  When a malformed or
      --  externally edited file contains duplicate canonical roots, keep the
      --  newest ordering marker instead of whichever duplicate appeared first.
      for Item of List.Entries loop
         Root := To_Unbounded_String (Normalized_Root_Path (To_String (Item.Root_Path)));
         if Valid_Project_Reference_Field (To_String (Root)) then
            declare
               Normalized : Recent_Project_Entry := Item;
               Existing_Index : Natural := Natural'Last;
            begin
               Normalized.Root_Path := Root;
               Normalized.Display_Name := To_Unbounded_String
                 (Sanitized_Field (To_String (Item.Display_Name)));
               if Length (Normalized.Display_Name) = 0 then
                  Normalized.Display_Name := To_Unbounded_String
                    (Ada.Directories.Simple_Name (To_String (Root)));
               end if;
               Normalized.Is_Unavailable := not Existing_Project_Root (To_String (Root));

               if not Result.Is_Empty then
                  for I in Result.First_Index .. Result.Last_Index loop
                     if To_String (Result (I).Root_Path) = To_String (Root) then
                        Existing_Index := I;
                        exit;
                     end if;
                  end loop;
               end if;

               if Existing_Index = Natural'Last then
                  Result.Append (Normalized);
               elsif Normalized.Last_Opened_Ms > Result (Existing_Index).Last_Opened_Ms then
                  Result.Replace_Element (Existing_Index, Normalized);
               end if;
            end;
         end if;
      end loop;

      if Result.Length > 1 then
         declare
            Tmp : Recent_Project_Entry;
         begin
            for I in Result.First_Index .. Result.Last_Index loop
               for J in I + 1 .. Result.Last_Index loop
                  if Result (J).Last_Opened_Ms > Result (I).Last_Opened_Ms
                    or else
                      (Result (J).Last_Opened_Ms = Result (I).Last_Opened_Ms
                       and then To_String (Result (J).Root_Path) < To_String (Result (I).Root_Path))
                  then
                     Tmp := Result (I);
                     Result.Replace_Element (I, Result (J));
                     Result.Replace_Element (J, Tmp);
                  end if;
               end loop;
            end loop;
         end;
      end if;

      while Config.Max_Entries > 0
        and then Natural (Result.Length) > Config.Max_Entries
      loop
         Result.Delete_Last;
      end loop;

      if Config.Max_Entries = 0 then
         Result.Clear;
      end if;

      List.Entries := Result;
   end Normalize;

   procedure Add_Or_Promote
     (List         : in out Recent_Project_List;
      Root_Path    : String;
      Display_Name : String;
      Now_Ms       : Natural;
      Config       : Recent_Project_Config := Default_Config)
   is
      Root : constant String := Normalized_Root_Path (Root_Path);
      Name : constant String := Sanitized_Field (Display_Name);
      Item : Recent_Project_Entry;
   begin
      if not Valid_Project_Reference_Field (Root) then
         return;
      end if;

      if not List.Entries.Is_Empty then
         for I in reverse List.Entries.First_Index .. List.Entries.Last_Index loop
            if To_String (List.Entries (I).Root_Path) = Root then
               List.Entries.Delete (I);
            end if;
         end loop;
      end if;

      Item.Root_Path := To_Unbounded_String (Root);
      if Name'Length > 0 then
         Item.Display_Name := To_Unbounded_String (Name);
      else
         Item.Display_Name := To_Unbounded_String (Ada.Directories.Simple_Name (Root));
      end if;
      Item.Last_Opened_Ms := Now_Ms;
      Item.Is_Unavailable := not Existing_Project_Root (Root);
      List.Entries.Prepend (Item);
      Normalize (List, Config);
   end Add_Or_Promote;

   procedure Remove
     (List      : in out Recent_Project_List;
      Root_Path : String)
   is
      Root : constant String := Normalized_Root_Path (Root_Path);
   begin
      if not Valid_Project_Reference_Field (Root) or else List.Entries.Is_Empty then
         return;
      end if;

      for I in reverse List.Entries.First_Index .. List.Entries.Last_Index loop
         if To_String (List.Entries (I).Root_Path) = Root then
            List.Entries.Delete (I);
         end if;
      end loop;
   end Remove;

   procedure Remove_At
     (List  : in out Recent_Project_List;
      Index : Positive)
   is
   begin
      if Index <= Count (List) then
         List.Entries.Delete (Natural (Index - 1));
      end if;
   end Remove_At;

   procedure Refresh_Availability
     (List : in out Recent_Project_List)
   is
      Item : Recent_Project_Entry;
   begin
      if List.Entries.Is_Empty then
         return;
      end if;

      for I in List.Entries.First_Index .. List.Entries.Last_Index loop
         Item := List.Entries (I);
         Item.Is_Unavailable := not Existing_Project_Root (To_String (Item.Root_Path));
            List.Entries.Replace_Element (I, Item);
      end loop;
   end Refresh_Availability;

   function Remove_Missing
     (List : in out Recent_Project_List) return Natural
   is
      Removed : Natural := 0;
   begin
      Refresh_Availability (List);
      if List.Entries.Is_Empty then
         return 0;
      end if;

      for I in reverse List.Entries.First_Index .. List.Entries.Last_Index loop
         if List.Entries (I).Is_Unavailable then
            List.Entries.Delete (I);
            Removed := Removed + 1;
         end if;
      end loop;
      return Removed;
   end Remove_Missing;

   function Config_Directory return String is
   begin
      if Length (Config_Directory_Override) > 0 then
         return To_String (Config_Directory_Override);
      elsif Ada.Environment_Variables.Exists ("XDG_CONFIG_HOME") then
         return Ada.Directories.Compose
           (Ada.Environment_Variables.Value ("XDG_CONFIG_HOME"), "editor");
      elsif Ada.Environment_Variables.Exists ("HOME") then
         return Ada.Directories.Compose
           (Ada.Directories.Compose (Ada.Environment_Variables.Value ("HOME"), ".config"),
            "editor");
      else
         return Ada.Directories.Compose (Ada.Directories.Current_Directory, ".editor");
      end if;
   end Config_Directory;

   function Recent_Projects_File_Path return String is
   begin
      return Ada.Directories.Compose (Config_Directory, "recent-projects");
   end Recent_Projects_File_Path;

   procedure Ensure_Parent_Directory
     (Path   : String;
      Status : out Recent_Project_Status)
   is
      Dir : constant String := Ada.Directories.Containing_Directory (Path);
   begin
      Status := Recent_Project_Ok;
      if Dir'Length > 0 and then not Ada.Directories.Exists (Dir) then
         Ada.Directories.Create_Path (Dir);
      end if;
   exception
      when others =>
         Status := Recent_Project_Write_Error;
   end Ensure_Parent_Directory;

   procedure Save_To_File
     (List   : Recent_Project_List;
      Path   : String;
      Status : out Recent_Project_Status)
   is
      File : Ada.Text_IO.File_Type;
      Copy : Recent_Project_List := List;
   begin
      Normalize (Copy, Default_Config);
      Ensure_Parent_Directory (Path, Status);
      if Status /= Recent_Project_Ok then
         return;
      end if;

      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put_Line (File, "editor-recent-projects-version=1");
      Ada.Text_IO.Put_Line (File, "[projects]");
      for Item of Copy.Entries loop
         Ada.Text_IO.Put_Line
           (File,
            To_String (Item.Root_Path)
            & "|name=" & Sanitized_Field (To_String (Item.Display_Name))
            & "|opened=" & Trimmed (Natural'Image (Item.Last_Opened_Ms)));
      end loop;
      Ada.Text_IO.Close (File);
      Status := Recent_Project_Ok;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Status := Recent_Project_Write_Error;
   end Save_To_File;

   function Starts_With (Text : String; Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Field_Value (Line : String; Prefix : String) return String is
   begin
      if Starts_With (Line, Prefix) then
         return Line (Line'First + Prefix'Length .. Line'Last);
      end if;
      return "";
   end Field_Value;

   procedure Parse_Project_Line
     (Line    : String;
      List    : in out Recent_Project_List;
      Ignored : out Boolean)
   is
      First_Bar  : Natural := 0;
      Second_Bar : Natural := 0;
   begin
      Ignored := False;
      for I in Line'Range loop
         if Line (I) = '|' then
            if First_Bar = 0 then
               First_Bar := I;
            else
               Second_Bar := I;
               exit;
            end if;
         end if;
      end loop;

      if First_Bar = 0 or else Second_Bar = 0 then
         Ignored := True;
         return;
      end if;

      declare
         Root_Field   : constant String := Line (Line'First .. First_Bar - 1);
         Name_Field   : constant String := Line (First_Bar + 1 .. Second_Bar - 1);
         Opened_Field : constant String := Line (Second_Bar + 1 .. Line'Last);
         Root         : constant String := Normalized_Root_Path (Root_Field);
         Name         : constant String := Field_Value (Name_Field, "name=");
         Opened_Text  : constant String := Field_Value (Opened_Field, "opened=");
         Opened       : Natural;
         Item         : Recent_Project_Entry;
      begin
         if not Valid_Project_Reference_Field (Root)
           or else Name'Length = 0
           or else Opened_Text'Length = 0
         then
            Ignored := True;
            return;
         end if;

         Opened := Natural'Value (Opened_Text);
         Item.Root_Path := To_Unbounded_String (Root);
         Item.Display_Name := To_Unbounded_String (Sanitized_Field (Name));
         Item.Last_Opened_Ms := Opened;
         Item.Is_Unavailable := not Existing_Project_Root (Root);
            List.Entries.Append (Item);
      exception
         when others =>
            Ignored := True;
      end;
   end Parse_Project_Line;

   procedure Load_From_File
     (Path   : String;
      List   : out Recent_Project_List;
      Status : out Recent_Project_Status)
   is
      File     : Ada.Text_IO.File_Type;
      Line_No  : Natural := 0;
      In_Items : Boolean := False;
      Partial  : Boolean := False;
   begin
      Last_Ignored_Load_Entries := 0;
      Clear (List);
      if not Ada.Directories.Exists (Path) then
         Status := Recent_Project_Not_Found;
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            Line_No := Line_No + 1;
            if Line_No = 1 then
               if Line /= "editor-recent-projects-version=1" then
                  Ada.Text_IO.Close (File);
                  Clear (List);
                  Status := Recent_Project_Invalid_Format;
                  return;
               end if;
            elsif Line = "[projects]" then
               In_Items := True;
            elsif In_Items then
               declare
                  Ignored : Boolean := False;
               begin
                  Parse_Project_Line (Line, List, Ignored);
                  if Ignored then
                     Partial := True;
                     if Last_Ignored_Load_Entries < Natural'Last then
                        Last_Ignored_Load_Entries := Last_Ignored_Load_Entries + 1;
                     end if;
                  end if;
               end;
            elsif Trimmed (Line)'Length /= 0 then
               Ada.Text_IO.Close (File);
               Clear (List);
               Status := Recent_Project_Invalid_Format;
               return;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);

      if Line_No = 0 then
         Clear (List);
         Status := Recent_Project_Invalid_Format;
         return;
      end if;

      Normalize (List, Default_Config);
      if Partial then
         Status := Recent_Project_Partial_Load;
      else
         Status := Recent_Project_Ok;
      end if;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Clear (List);
         Status := Recent_Project_Read_Error;
   end Load_From_File;

   procedure Set_Config_Directory_For_Tests
     (Path : String)
   is
   begin
      Config_Directory_Override := To_Unbounded_String (Path);
   end Set_Config_Directory_For_Tests;

   procedure Clear_Config_Directory_Override is
   begin
      Config_Directory_Override := Null_Unbounded_String;
   end Clear_Config_Directory_Override;

end Editor.Recent_Projects;
