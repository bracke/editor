with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.State;

package body Editor.Buffers.Path_And_Labeling is

   function Metadata_Label_Max_Length return Positive is
   begin
      return 160;
   end Metadata_Label_Max_Length;

   function Bounded_Metadata_Label (Value : String) return String is
      Max_Length : constant Natural := Metadata_Label_Max_Length;
   begin
      if Value'Length <= Max_Length then
         return Value;
      elsif Max_Length <= 3 then
         return Value (Value'First .. Value'First + Max_Length - 1);
      else
         return Value (Value'First .. Value'First + Max_Length - 4) & "...";
      end if;
   end Bounded_Metadata_Label;

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

end Editor.Buffers.Path_And_Labeling;
