with Ada.Containers;
with Ada.Directories;
with Ada.Text_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Working_Context;
with Editor.External_Producers;

package body Editor.Build_Candidates is

   use type Ada.Containers.Count_Type;
   use type Editor.External_Producers.Build_Tool_Kind;
   use type Ada.Directories.File_Kind;
   use type Editor.Build_Working_Context.Build_Working_Context_Validation_Status;

   function Trim (S : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (S, Ada.Strings.Both);
   end Trim;

   function Contains_Control (Text : String) return Boolean is
   begin
      for C of Text loop
         if Character'Pos (C) < 32 or else Character'Pos (C) = 127 then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Control;



   function Base_Name (Path : String) return String is
      Last_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = '\' then
            Last_Slash := I;
         end if;
      end loop;
      if Last_Slash = 0 then
         return Path;
      elsif Last_Slash < Path'Last then
         return Path (Last_Slash + 1 .. Path'Last);
      else
         return "project";
      end if;
   end Base_Name;

   function Normalize_Separators (Path : String) return String is
      Result : String := Path;
   begin
      for I in Result'Range loop
         if Result (I) = Character'Val (16#5C#) then
            Result (I) := '/';
         end if;
      end loop;
      return Result;
   end Normalize_Separators;

   function Canonical_Existing_Path (Path : String) return String is
   begin
      if Trim (Path)'Length = 0 then
         return "";
      elsif Ada.Directories.Exists (Path) then
         return Normalize_Separators (Ada.Directories.Full_Name (Path));
      else
         return Normalize_Separators (Path);
      end if;
   exception
      when others =>
         return Normalize_Separators (Path);
   end Canonical_Existing_Path;

   function Is_Path_Within_Project_Root (Path, Project_Root : String) return Boolean is
      Canonical_Path : constant String := Canonical_Existing_Path (Path);
      Canonical_Root : constant String := Canonical_Existing_Path (Project_Root);
   begin
      return Canonical_Path = Canonical_Root
        or else (Canonical_Path'Length > Canonical_Root'Length
                 and then Canonical_Path (Canonical_Path'First .. Canonical_Path'First + Canonical_Root'Length - 1) = Canonical_Root
                 and then Canonical_Path (Canonical_Path'First + Canonical_Root'Length) = '/');
   end Is_Path_Within_Project_Root;

   function Is_Safe_Project_Relative_Path (Path : String) return Boolean is
      Start : Positive := Path'First;
   begin
      if Trim (Path)'Length = 0
        or else Path (Path'First) = '/'
        or else Path (Path'First) = Character'Val (16#5C#)
        or else Ada.Strings.Fixed.Index (Path, "//") > 0
        or else Ada.Strings.Fixed.Index (Path, "\") > 0
      then
         return False;
      end if;

      while Start <= Path'Last loop
         declare
            Next : Natural := Start;
         begin
            while Next <= Path'Last and then Path (Next) /= '/' loop
               Next := Next + 1;
            end loop;
            if Next = Start then
               return False;
            elsif Path (Start .. Next - 1) = "."
              or else Path (Start .. Next - 1) = ".."
            then
               return False;
            end if;
            Start := Next + 1;
         end;
      end loop;
      return True;
   end Is_Safe_Project_Relative_Path;


   function Path_Is_Readable_Ordinary_File (Path : String) return Boolean is
      File : Ada.Text_IO.File_Type;
   begin
      if Trim (Path)'Length = 0
        or else not Ada.Directories.Exists (Path)
        or else Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File
      then
         return False;
      end if;

      --  treats discovered source paths as executable build-request
      --  inputs only when the represented project file can actually be opened
      --  by the editor process.  Discovery still does not parse TOML/GPR
      --  semantics; this is a bounded open/close readability check used only
      --  to mark stale or inaccessible candidates unavailable.
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      Ada.Text_IO.Close (File);
      return True;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return False;
   end Path_Is_Readable_Ordinary_File;

   function Source_Relative_Path
     (Project_Root : String;
      Source_Path  : String) return String
   is
   begin
      if Is_Path_Within_Project_Root (Source_Path, Project_Root)
        and then Source_Path'Length > Project_Root'Length
      then
         return Source_Path (Source_Path'First + Project_Root'Length + 1 .. Source_Path'Last);
      else
         return Source_Path;
      end if;
   end Source_Relative_Path;

   function Empty_Candidates return Build_Candidate_Vector is
   begin
      return Build_Candidate_Vectors.Empty_Vector;
   end Empty_Candidates;

   function Argument_Count
     (Candidate : Build_Candidate_Record) return Natural
   is
   begin
      return Natural (Candidate.Structured_Arguments.Length);
   end Argument_Count;

   function Candidate_Id_For_Alire
     (Project_Root : String) return String
   is
   begin
      return "alire:" & Project_Root & "/alire.toml";
   end Candidate_Id_For_Alire;

   function Candidate_Id_For_Gpr
     (Project_Root : String;
      Project_Relative_Gpr_Path : String) return String
   is
   begin
      return "gpr:" & Project_Root & "/" & Project_Relative_Gpr_Path;
   end Candidate_Id_For_Gpr;

   function Alire_Candidate
     (Project_Root : String) return Build_Candidate_Record
   is
      Args : Build_Candidate_Argument_Vector :=
        Editor.External_Producers.Process_Argument_Vectors.Empty_Vector;
      Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Current_Project_Root (Project_Root);
   begin
      Args.Append (To_Unbounded_String ("build"));
      return
        (Candidate_Id => To_Unbounded_String (Candidate_Id_For_Alire (Project_Root)),
         Candidate_Kind => Build_Candidate_Alire_Project,
         Display_Label => To_Unbounded_String ("Alire project: " & Base_Name (Project_Root)),
         Tool_Kind => Editor.External_Producers.Alire_Build_Tool,
         Structured_Arguments => Args,
         Working_Context => Context,
         Source_Path_If_Represented => To_Unbounded_String (Project_Root & "/alire.toml"),
         Discovery_Source => Build_Candidate_Source_Alire_Toml,
         Validation_Status => Build_Candidate_Valid,
         Validation_Message => To_Unbounded_String ("Alire build candidate"));
   end Alire_Candidate;

   function Gprbuild_Candidate
     (Project_Root : String;
      Project_Relative_Gpr_Path : String) return Build_Candidate_Record
   is
      Args : Build_Candidate_Argument_Vector :=
        Editor.External_Producers.Process_Argument_Vectors.Empty_Vector;
      Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.Current_Project_Root (Project_Root);
   begin
      Args.Append (To_Unbounded_String ("-P"));
      Args.Append (To_Unbounded_String (Project_Relative_Gpr_Path));
      return
        (Candidate_Id => To_Unbounded_String (Candidate_Id_For_Gpr (Project_Root, Project_Relative_Gpr_Path)),
         Candidate_Kind => Build_Candidate_Gpr_Project,
         Display_Label => To_Unbounded_String ("GPR: " & Project_Relative_Gpr_Path),
         Tool_Kind => Editor.External_Producers.GPRbuild_Tool,
         Structured_Arguments => Args,
         Working_Context => Context,
         Source_Path_If_Represented => To_Unbounded_String (Project_Root & "/" & Project_Relative_Gpr_Path),
         Discovery_Source => Build_Candidate_Source_Gpr_File,
         Validation_Status => Build_Candidate_Valid,
         Validation_Message => To_Unbounded_String ("GPRbuild candidate"));
   end Gprbuild_Candidate;

   function Manual_Request_Candidate return Build_Candidate_Record is
   begin
      return
        (Candidate_Id => To_Unbounded_String ("manual"),
         Candidate_Kind => Build_Candidate_Manual_Request,
         Display_Label => To_Unbounded_String ("Manual build request"),
         Tool_Kind => Editor.External_Producers.No_Build_Tool,
         Structured_Arguments => Editor.External_Producers.Process_Argument_Vectors.Empty_Vector,
         Working_Context => Editor.Build_Working_Context.None,
         Source_Path_If_Represented => Null_Unbounded_String,
         Discovery_Source => Build_Candidate_Source_Manual_UI,
         Validation_Status => Build_Candidate_Rejected_Unstructured,
         Validation_Message => To_Unbounded_String
           ("Manual request candidates are disabled; select a discovered Build candidate."));
   end Manual_Request_Candidate;

   function Build_Candidate_Source_Kind_Label
     (Source : Build_Candidate_Source) return String
   is
   begin
      case Source is
         when Build_Candidate_Source_None => return "Unavailable";
         when Build_Candidate_Source_Alire_Toml => return "Alire";
         when Build_Candidate_Source_Gpr_File => return "GPR project files";
         when Build_Candidate_Source_Manual_UI => return "Manual request";
      end case;
   end Build_Candidate_Source_Kind_Label;

   function Build_Candidate_Project_Relative_Label
     (Candidate : Build_Candidate_Record) return String
   is
      Root : constant String := To_String (Candidate.Working_Context.Canonical_Path_If_Available);
      Source : constant String := To_String (Candidate.Source_Path_If_Represented);
   begin
      if Candidate.Candidate_Kind = Build_Candidate_Alire_Project then
         return Base_Name (Root);
      elsif Root'Length > 0 and then Source'Length > 0 then
         return Source_Relative_Path (Root, Source);
      elsif Source'Length > 0 then
         return Source;
      else
         return To_String (Candidate.Display_Label);
      end if;
   end Build_Candidate_Project_Relative_Label;

   function Build_Candidate_Disabled_Reason
     (Candidate : Build_Candidate_Record) return String
   is
      Status : constant Build_Candidate_Validation_Status :=
        Validate_Candidate (Candidate);
   begin
      if Status = Build_Candidate_Valid then
         return "";
      elsif Candidate.Validation_Status = Status
        and then Length (Candidate.Validation_Message) > 0
      then
         return To_String (Candidate.Validation_Message);
      else
         case Status is
            when Build_Candidate_Valid => return "";
            when Build_Candidate_Unavailable => return "candidate path missing or unavailable";
            when Build_Candidate_Rejected_Unstructured => return "candidate request could not be formed";
            when Build_Candidate_Rejected_Unsafe_Source => return "candidate path outside project root";
            when Build_Candidate_Rejected_Shell_Text => return "candidate request is not structured argv";
            when Build_Candidate_Rejected_Persisted_State => return "candidate must be refreshed";
         end case;
      end if;
   end Build_Candidate_Disabled_Reason;

   function Validate_Candidate
     (Candidate : Build_Candidate_Record)
      return Build_Candidate_Validation_Status
   is
   begin
      if Candidate.Candidate_Kind = Build_Candidate_None then
         return Build_Candidate_Unavailable;
      elsif Candidate.Candidate_Kind = Build_Candidate_Manual_Request
        or else Candidate.Discovery_Source = Build_Candidate_Source_Manual_UI
      then
         return Build_Candidate_Rejected_Unstructured;
      elsif Candidate.Tool_Kind = Editor.External_Producers.Custom_Build_Tool then
         return Build_Candidate_Rejected_Unstructured;
      elsif Candidate.Discovery_Source not in
        Build_Candidate_Source_Alire_Toml |
        Build_Candidate_Source_Gpr_File |
        Build_Candidate_Source_Manual_UI
      then
         return Build_Candidate_Rejected_Unsafe_Source;
      elsif Has_Raw_Shell_Command_Field (Candidate) then
         return Build_Candidate_Rejected_Shell_Text;
      elsif Has_Remembered_Consent_Field (Candidate)
        or else Has_Process_State_Field (Candidate)
      then
         return Build_Candidate_Rejected_Persisted_State;
      end if;

      for Arg of Candidate.Structured_Arguments loop
         declare
            S : constant String := To_String (Arg);
         begin
            if Trim (S)'Length = 0 or else Contains_Control (S) then
               return Build_Candidate_Rejected_Shell_Text;
            end if;
         end;
      end loop;

      if Candidate.Candidate_Kind in
        Build_Candidate_Alire_Project | Build_Candidate_Gpr_Project
        and then Editor.Build_Working_Context.Validate_Build_Working_Context
          (Candidate.Working_Context) /=
          Editor.Build_Working_Context.Build_Working_Context_Valid
      then
         return Build_Candidate_Rejected_Unsafe_Source;
      end if;

      declare
         Root : constant String :=
           To_String (Candidate.Working_Context.Canonical_Path_If_Available);
         Source : constant String := To_String (Candidate.Source_Path_If_Represented);
      begin
         if Candidate.Candidate_Kind = Build_Candidate_Gpr_Project then
            if Candidate.Structured_Arguments.Length < 2
              or else not Is_Safe_Project_Relative_Path
                (To_String (Candidate.Structured_Arguments.Element (1)))
              or else Source'Length = 0
              or else not Is_Path_Within_Project_Root (Source, Root)
            then
               return Build_Candidate_Rejected_Unsafe_Source;
            elsif Ada.Directories.Exists (Root)
              and then not Path_Is_Readable_Ordinary_File (Source)
            then
               return Build_Candidate_Unavailable;
            end if;
         elsif Candidate.Candidate_Kind = Build_Candidate_Alire_Project then
            if Source'Length = 0
              or else not Is_Path_Within_Project_Root (Source, Root)
            then
               return Build_Candidate_Rejected_Unsafe_Source;
            elsif Ada.Directories.Exists (Root)
              and then not Path_Is_Readable_Ordinary_File (Source)
            then
               return Build_Candidate_Unavailable;
            end if;
         end if;
      end;

      return Build_Candidate_Valid;
   end Validate_Candidate;

   procedure Swap
     (Candidates : in out Build_Candidate_Vector;
      Left       : Natural;
      Right      : Natural)
   is
      L : constant Build_Candidate_Record := Candidates.Element (Left);
   begin
      Candidates.Replace_Element (Left, Candidates.Element (Right));
      Candidates.Replace_Element (Right, L);
   end Swap;

   function Path_Depth (Path : String) return Natural is
      Depth : Natural := 0;
   begin
      for C of Path loop
         if C = '/' then
            Depth := Depth + 1;
         end if;
      end loop;
      return Depth;
   end Path_Depth;

   function Lower (S : String) return String is
      Result : String := S;
   begin
      for I in Result'Range loop
         if Result (I) in 'A' .. 'Z' then
            Result (I) := Character'Val (Character'Pos (Result (I)) + 32);
         end if;
      end loop;
      return Result;
   end Lower;

   function Gpr_Relative_Path (Candidate : Build_Candidate_Record) return String is
   begin
      if Candidate.Structured_Arguments.Length >= 2 then
         return To_String (Candidate.Structured_Arguments.Element (1));
      else
         return To_String (Candidate.Source_Path_If_Represented);
      end if;
   end Gpr_Relative_Path;

   function Rank (Candidate : Build_Candidate_Record) return Natural is
      Rel : constant String := Lower (Gpr_Relative_Path (Candidate));
      Base : constant String := Lower (Base_Name (Rel));
      Root_Base : constant String := Lower
        (Base_Name (To_String (Candidate.Working_Context.Canonical_Path_If_Available)));
      Base_Without_Extension : constant String :=
        (if Base'Length > 4 and then Base (Base'Last - 3 .. Base'Last) = ".gpr" then
            Base (Base'First .. Base'Last - 4)
         else
            Base);
   begin
      case Candidate.Candidate_Kind is
         when Build_Candidate_Alire_Project =>
            return 0;
         when Build_Candidate_Gpr_Project =>
            if Path_Depth (Rel) = 0 and then Base_Without_Extension = Root_Base then
               return 5;
            elsif Path_Depth (Rel) = 0 then
               return 10;
            elsif Ada.Strings.Fixed.Index (Rel, "test") > 0
              or else Ada.Strings.Fixed.Index (Rel, "example") > 0
            then
               return 40 + Path_Depth (Rel);
            elsif Ada.Strings.Fixed.Index (Base, "app") > 0
              or else Ada.Strings.Fixed.Index (Base, "main") > 0
              or else Ada.Strings.Fixed.Index (Base, "demo") > 0
            then
               return 20 + Path_Depth (Rel);
            else
               return 30 + Path_Depth (Rel);
            end if;
         when Build_Candidate_Manual_Request => return 90;
         when Build_Candidate_None => return 99;
      end case;
   end Rank;

   function Less (Left, Right : Build_Candidate_Record) return Boolean is
   begin
      if Rank (Left) /= Rank (Right) then
         return Rank (Left) < Rank (Right);
      end if;
      return To_String (Left.Candidate_Id) < To_String (Right.Candidate_Id);
   end Less;

   procedure Sort_Build_Candidates
     (Candidates : in out Build_Candidate_Vector)
   is
   begin
      if Candidates.Length < 2 then
         return;
      end if;
      for I in Candidates.First_Index .. Candidates.Last_Index loop
         for J in I + 1 .. Candidates.Last_Index loop
            if Less (Candidates.Element (J), Candidates.Element (I)) then
               Swap (Candidates, I, J);
            end if;
         end loop;
      end loop;
   end Sort_Build_Candidates;

   procedure Append_Unique_Candidate
     (Candidates : in out Build_Candidate_Vector;
      Candidate  : Build_Candidate_Record)
   is
      Id : constant String := To_String (Candidate.Candidate_Id);
   begin
      for Existing of Candidates loop
         if To_String (Existing.Candidate_Id) = Id then
            return;
         end if;
      end loop;
      Candidates.Append (Candidate);
      Sort_Build_Candidates (Candidates);
   end Append_Unique_Candidate;

   function Has_Raw_Shell_Command_Field
     (Candidate : Build_Candidate_Record) return Boolean
   is
      pragma Unreferenced (Candidate);
   begin
      return False;
   end Has_Raw_Shell_Command_Field;

   function Has_Remembered_Consent_Field
     (Candidate : Build_Candidate_Record) return Boolean
   is
      pragma Unreferenced (Candidate);
   begin
      return False;
   end Has_Remembered_Consent_Field;

   function Has_Process_State_Field
     (Candidate : Build_Candidate_Record) return Boolean
   is
      pragma Unreferenced (Candidate);
   begin
      return False;
   end Has_Process_State_Field;

   function Assert_Build_Candidate_Is_Structured
     (Candidate : Build_Candidate_Record) return Boolean
   is
   begin
      return Validate_Candidate (Candidate) = Build_Candidate_Valid
        and then not Has_Raw_Shell_Command_Field (Candidate)
        and then Candidate.Tool_Kind /= Editor.External_Producers.Custom_Build_Tool
        and then To_String (Candidate.Candidate_Id)'Length > 0
        and then To_String (Candidate.Display_Label) /= To_String (Candidate.Candidate_Id);
   end Assert_Build_Candidate_Is_Structured;

   function Assert_Build_Candidate_Is_Transient
     (Candidate : Build_Candidate_Record) return Boolean
   is
   begin
      return not Has_Remembered_Consent_Field (Candidate)
        and then not Has_Process_State_Field (Candidate)
        and then Candidate.Validation_Status /= Build_Candidate_Rejected_Persisted_State;
   end Assert_Build_Candidate_Is_Transient;

   function Assert_Build_Candidate_Persistence_Excluded
     (Candidate : Build_Candidate_Record) return Boolean
   is
      pragma Unreferenced (Candidate);
   begin
      return True;
   end Assert_Build_Candidate_Persistence_Excluded;

   function Assert_Build_Candidate_List_Is_Deterministic
     (Candidates : Build_Candidate_Vector) return Boolean
   is
   begin
      if Candidates.Length < 2 then
         return True;
      end if;
      for I in Candidates.First_Index .. Candidates.Last_Index - 1 loop
         if Less (Candidates.Element (I + 1), Candidates.Element (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Build_Candidate_List_Is_Deterministic;

end Editor.Build_Candidates;
