with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Editor.Workspace_Persistence.Text_Format; use Editor.Workspace_Persistence.Text_Format;
with Editor.Workspace_Persistence.Snapshot_Model; use Editor.Workspace_Persistence.Snapshot_Model;
with Editor.Workspace_Persistence.Parsing; use Editor.Workspace_Persistence.Parsing;
with Editor.Workspace_Persistence.File_IO; use Editor.Workspace_Persistence.File_IO;
with Editor.Workspace_Persistence.Audits; use Editor.Workspace_Persistence.Audits;

package body Editor.Workspace_Persistence.Path_Validation is

   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;

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


end Editor.Workspace_Persistence.Path_Validation;
