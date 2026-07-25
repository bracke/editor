with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Editor.Workspace_Persistence.Path_Validation; use Editor.Workspace_Persistence.Path_Validation;
with Editor.Workspace_Persistence.Snapshot_Model; use Editor.Workspace_Persistence.Snapshot_Model;
with Editor.Workspace_Persistence.Parsing; use Editor.Workspace_Persistence.Parsing;
with Editor.Workspace_Persistence.File_IO; use Editor.Workspace_Persistence.File_IO;
with Editor.Workspace_Persistence.Audits; use Editor.Workspace_Persistence.Audits;

package body Editor.Workspace_Persistence.Text_Format is

   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;

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


end Editor.Workspace_Persistence.Text_Format;
