with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Build_Working_Context is

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Contains_Control (Text : String) return Boolean is
   begin
      for C of Text loop
         if Character'Pos (C) < 32 or else Character'Pos (C) = 127 then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Control;

   function Contains_Shell_Syntax (Text : String) return Boolean is
      Shell_Meta : constant String := "|&;<>()`$\\";
   begin
      for C of Text loop
         for M of Shell_Meta loop
            if C = M then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Contains_Shell_Syntax;

   function Is_Path_Like (Text : String) return Boolean is
   begin
      for C of Text loop
         if C = '/' or else C = '\' or else C = ':' then
            return True;
         end if;
      end loop;
      return False;
   end Is_Path_Like;

   function With_Status
     (Context : Build_Working_Context_Record)
      return Build_Working_Context_Record
   is
      Result : Build_Working_Context_Record := Context;
      Status : constant Build_Working_Context_Validation_Status :=
        Validate_Build_Working_Context (Context);
   begin
      Result.Validation_Status := Status;
      Result.Validation_Message := To_Unbounded_String
        (Build_Working_Context_Message (Status));
      if To_String (Result.Display_Label)'Length = 0 then
         Result.Display_Label := To_Unbounded_String
           (Build_Working_Context_Display_Label (Result));
      end if;
      return Result;
   end With_Status;

   function None return Build_Working_Context_Record is
   begin
      return With_Status
        ((Kind => Build_Working_Context_None,
          Display_Label => Null_Unbounded_String,
          Canonical_Path_If_Available => Null_Unbounded_String,
          Source_Kind => Working_Context_Source_None,
          Validation_Status => Build_Working_Context_Rejected_None,
          Validation_Message => Null_Unbounded_String));
   end None;

   function Unavailable (Reason : String) return Build_Working_Context_Record is
   begin
      return With_Status
        ((Kind => Build_Working_Context_Unavailable,
          Display_Label => To_Unbounded_String (Reason),
          Canonical_Path_If_Available => Null_Unbounded_String,
          Source_Kind => Working_Context_Source_Unavailable,
          Validation_Status => Build_Working_Context_Rejected_Unavailable,
          Validation_Message => Null_Unbounded_String));
   end Unavailable;

   function Current_Project_Root
     (Canonical_Path : String) return Build_Working_Context_Record
   is
   begin
      return With_Status
        ((Kind => Build_Working_Context_Current_Project_Root,
          Display_Label => To_Unbounded_String ("current-project-root"),
          Canonical_Path_If_Available => To_Unbounded_String (Trimmed (Canonical_Path)),
          Source_Kind => Working_Context_Source_Canonical_Project,
          Validation_Status => Build_Working_Context_Valid,
          Validation_Message => Null_Unbounded_String));
   end Current_Project_Root;

   function Current_Workspace_Root
     (Canonical_Path : String) return Build_Working_Context_Record
   is
   begin
      return With_Status
        ((Kind => Build_Working_Context_Current_Workspace_Root,
          Display_Label => To_Unbounded_String ("active-workspace-root"),
          Canonical_Path_If_Available => To_Unbounded_String (Trimmed (Canonical_Path)),
          Source_Kind => Working_Context_Source_Canonical_Workspace,
          Validation_Status => Build_Working_Context_Valid,
          Validation_Message => Null_Unbounded_String));
   end Current_Workspace_Root;

   function Test_Fixture
     (Canonical_Path : String := "test-fixture-context")
      return Build_Working_Context_Record
   is
   begin
      return With_Status
        ((Kind => Build_Working_Context_Test_Fixture,
          Display_Label => To_Unbounded_String ("test-fixture-context"),
          Canonical_Path_If_Available => To_Unbounded_String (Trimmed (Canonical_Path)),
          Source_Kind => Working_Context_Source_Test_Fixture,
          Validation_Status => Build_Working_Context_Valid,
          Validation_Message => Null_Unbounded_String));
   end Test_Fixture;

   function Unsafe_Context
     (Kind         : Build_Working_Context_Kind;
      Label        : String;
      Source_Kind  : Working_Context_Source_Kind;
      Path_If_Any  : String := "") return Build_Working_Context_Record
   is
   begin
      return With_Status
        ((Kind => Kind,
          Display_Label => To_Unbounded_String (Label),
          Canonical_Path_If_Available => To_Unbounded_String (Path_If_Any),
          Source_Kind => Source_Kind,
          Validation_Status => Build_Working_Context_Rejected_Unsafe_Source,
          Validation_Message => Null_Unbounded_String));
   end Unsafe_Context;

   function Context_From_Explicit_Token
     (Token : String) return Build_Working_Context_Record
   is
      Clean : constant String := Trimmed (Token);
   begin
      if Clean = "current-project-root" then
         return Current_Project_Root (Clean);
      elsif Clean = "active-workspace-root" then
         return Current_Workspace_Root (Clean);
      elsif Clean = "test-fixture-context" then
         return Test_Fixture;
      elsif Clean'Length = 0 then
         return None;
      elsif Contains_Shell_Syntax (Clean) then
         return Unsafe_Context
           (Build_Working_Context_Unavailable, Clean,
            Working_Context_Source_Shell_Derived, Clean);
      elsif Is_Path_Like (Clean) then
         return Unsafe_Context
           (Build_Working_Context_Unavailable, Clean,
            Working_Context_Source_Raw_Text, Clean);
      else
         return Unsafe_Context
           (Build_Working_Context_Unavailable, Clean,
            Working_Context_Source_Raw_Text, Clean);
      end if;
   end Context_From_Explicit_Token;

   function Validate_Build_Working_Context
     (Context : Build_Working_Context_Record)
      return Build_Working_Context_Validation_Status
   is
      Label : constant String := To_String (Context.Display_Label);
      Path  : constant String := To_String (Context.Canonical_Path_If_Available);
   begin
      case Context.Source_Kind is
         when Working_Context_Source_Raw_Text =>
            return Build_Working_Context_Rejected_Raw_Text;
         when Working_Context_Source_Shell_Derived =>
            return Build_Working_Context_Rejected_Shell_Derived;
         when Working_Context_Source_Implicit_Derived =>
            return Build_Working_Context_Rejected_Implicit_Derived;
         when Working_Context_Source_Filesystem_Discovered =>
            return Build_Working_Context_Rejected_Filesystem_Discovered;
         when Working_Context_Source_Persisted =>
            return Build_Working_Context_Rejected_Persisted;
         when others =>
            null;
      end case;

      if Contains_Control (Label) or else Contains_Control (Path) then
         return Build_Working_Context_Rejected_Invalid_Label;
      end if;

      case Context.Kind is
         when Build_Working_Context_None =>
            return Build_Working_Context_Rejected_None;
         when Build_Working_Context_Unavailable =>
            return Build_Working_Context_Rejected_Unavailable;
         when Build_Working_Context_Current_Project_Root =>
            if Context.Source_Kind /= Working_Context_Source_Canonical_Project then
               return Build_Working_Context_Rejected_Missing_Canonical_Source;
            elsif Trimmed (Path)'Length = 0 then
               return Build_Working_Context_Rejected_Invalid_Path;
            end if;
         when Build_Working_Context_Current_Workspace_Root =>
            if Context.Source_Kind /= Working_Context_Source_Canonical_Workspace then
               return Build_Working_Context_Rejected_Missing_Canonical_Source;
            elsif Trimmed (Path)'Length = 0 then
               return Build_Working_Context_Rejected_Invalid_Path;
            end if;
         when Build_Working_Context_Test_Fixture =>
            if Context.Source_Kind /= Working_Context_Source_Test_Fixture then
               return Build_Working_Context_Rejected_Missing_Canonical_Source;
            elsif Trimmed (Path)'Length = 0 then
               return Build_Working_Context_Rejected_Invalid_Path;
            end if;
      end case;

      return Build_Working_Context_Valid;
   end Validate_Build_Working_Context;

   function Build_Working_Context_Display_Label
     (Context : Build_Working_Context_Record) return String
   is
   begin
      if To_String (Context.Display_Label)'Length > 0 then
         return To_String (Context.Display_Label);
      end if;

      case Context.Kind is
         when Build_Working_Context_None => return "";
         when Build_Working_Context_Current_Project_Root => return "current-project-root";
         when Build_Working_Context_Current_Workspace_Root => return "active-workspace-root";
         when Build_Working_Context_Test_Fixture => return "test-fixture-context";
         when Build_Working_Context_Unavailable => return "working-context-unavailable";
      end case;
   end Build_Working_Context_Display_Label;

   function Build_Working_Context_Message
     (Status : Build_Working_Context_Validation_Status) return String
   is
   begin
      case Status is
         when Build_Working_Context_Valid => return "Build working context ready";
         when Build_Working_Context_Rejected_None => return "Build working context required";
         when Build_Working_Context_Rejected_Unavailable => return "No canonical project/workspace context";
         when Build_Working_Context_Rejected_Missing_Canonical_Source =>
            return "Build working context lacks canonical source";
         when Build_Working_Context_Rejected_Unsafe_Source => return "Build working context source rejected";
         when Build_Working_Context_Rejected_Raw_Text => return "Raw build working directory text rejected";
         when Build_Working_Context_Rejected_Shell_Derived => return "Shell-derived build working context rejected";
         when Build_Working_Context_Rejected_Implicit_Derived =>
            return "Implicit-derived build working context rejected";
         when Build_Working_Context_Rejected_Filesystem_Discovered =>
            return "Filesystem-discovered build working context rejected";
         when Build_Working_Context_Rejected_Persisted => return "Persisted build working context rejected";
         when Build_Working_Context_Rejected_Invalid_Label => return "Build working context label invalid";
         when Build_Working_Context_Rejected_Invalid_Path => return "Build working context canonical path required";
      end case;
   end Build_Working_Context_Message;

   function Request_Identity_Token
     (Context : Build_Working_Context_Record) return String
   is
   begin
      return Build_Working_Context_Kind'Image (Context.Kind) & ":" &
        Working_Context_Source_Kind'Image (Context.Source_Kind) & ":" &
        To_String (Context.Display_Label) & ":" &
        To_String (Context.Canonical_Path_If_Available) & ":" &
        Build_Working_Context_Validation_Status'Image
          (Validate_Build_Working_Context (Context));
   end Request_Identity_Token;

   function Assert_Build_Working_Context_Is_Structured
     (Context : Build_Working_Context_Record) return Boolean
   is
   begin
      return Validate_Build_Working_Context (Context) = Build_Working_Context_Valid
        or else Context.Kind in Build_Working_Context_None | Build_Working_Context_Unavailable;
   end Assert_Build_Working_Context_Is_Structured;

   function Assert_Build_Working_Context_Is_Transient
     (Context : Build_Working_Context_Record) return Boolean
   is
   begin
      return Context.Source_Kind /= Working_Context_Source_Persisted;
   end Assert_Build_Working_Context_Is_Transient;

   function Assert_Build_Working_Context_Does_Not_Probe_Filesystem
     (Context : Build_Working_Context_Record) return Boolean
   is
   begin
      return Context.Source_Kind /= Working_Context_Source_Filesystem_Discovered;
   end Assert_Build_Working_Context_Does_Not_Probe_Filesystem;

   function Assert_Build_Working_Context_Persistence_Excluded
     (Context : Build_Working_Context_Record) return Boolean
   is
   begin
      return Context.Source_Kind /= Working_Context_Source_Persisted;
   end Assert_Build_Working_Context_Persistence_Excluded;

end Editor.Build_Working_Context;
