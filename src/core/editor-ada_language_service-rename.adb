with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Action_Router;
with Editor.Ada_Diagnostic_Navigation;
with Editor.Ada_Diagnostic_Panel_Projection;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Diagnostic_Status_Line;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostic_Text_Lines;
with Editor.External_Producers.Diagnostics_Types;
with Editor.Syntax;

with Editor.Ada_Language_Service.Navigation; use Editor.Ada_Language_Service.Navigation;
with Editor.Ada_Language_Service.Requests; use Editor.Ada_Language_Service.Requests;

package body Editor.Ada_Language_Service.Rename is

   use type Editor.Ada_Language_Model.Symbol_Kind;

   function Target_Status_Result
     (Status : Service_Status) return Language_Target
   is
      Result : Language_Target;
   begin
      Result.Status := Status;
      return Result;
   end Target_Status_Result;

   function Target_Set_Status_Result
     (Status : Service_Status) return Language_Target_Set
   is
      Result : Language_Target_Set;
   begin
      Result.Status := Status;
      return Result;
   end Target_Set_Status_Result;

   function Completion_Status_Result
     (Status : Service_Status) return Completion_Result
   is
      Result : Completion_Result;
   begin
      Result.Status := Status;
      return Result;
   end Completion_Status_Result;

   function Hover_Status_Result
     (Status : Service_Status) return Hover_Result
   is
      Result : Hover_Result;
   begin
      Result.Status := Status;
      return Result;
   end Hover_Status_Result;

   function Rename_Status_Result
     (Status : Service_Status) return Rename_Preview
   is
      Result : Rename_Preview;
   begin
      Result.Status := Status;
      return Result;
   end Rename_Status_Result;

   function Starts_With (Text, Prefix : String) return Boolean is
      Normal_Text   : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Text);
      Normal_Prefix : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Prefix);
   begin
      if Normal_Prefix'Length = 0 then
         return True;
      end if;

      return Normal_Text'Length >= Normal_Prefix'Length
        and then Normal_Text
          (Normal_Text'First .. Normal_Text'First + Normal_Prefix'Length - 1)
        = Normal_Prefix;
   end Starts_With;

   function Normalized_Path (Text : String) return String is
      Result   : String := Text;
      Write    : Natural := Result'First;
      Last     : Natural;
      Prev_Sep : Boolean := False;
   begin
      if Text'Length = 0 then
         return "";
      end if;

      for I in Text'Range loop
         declare
            Ch : Character := Text (I);
         begin
            if Character'Pos (Ch) = 16#5C# then
               Ch := '/';
            end if;

            if Ch = '/' then
               if not Prev_Sep then
                  Result (Write) := Ch;
                  Write := Write + 1;
               end if;
               Prev_Sep := True;
            else
               Result (Write) := Ch;
               Write := Write + 1;
               Prev_Sep := False;
            end if;
         end;
      end loop;

      if Write = Result'First then
         return "";
      end if;

      Last := Write - 1;
      while Last >= Result'First and then Result (Last) = '/' loop
         if Last = 0 then
            exit;
         end if;
         Last := Last - 1;
      end loop;

      if Last < Result'First then
         return "";
      end if;

      return Result (Result'First .. Last);
   end Normalized_Path;

   function Same_Path (Left, Right : String) return Boolean is
   begin
      return Normalized_Path (Left) = Normalized_Path (Right);
   end Same_Path;

   function Path_Matches_Label (Path, Label : String) return Boolean
   is
      Normal_Path  : constant String := Normalized_Path (Path);
      Normal_Label : constant String := Normalized_Path (Label);

      function Component_Suffix_Matches
        (Longer  : String;
         Shorter : String) return Boolean
      is
         Offset : Natural;
      begin
         if Longer'Length <= Shorter'Length then
            return False;
         end if;

         Offset := Longer'Last - Shorter'Length + 1;
         return Offset > Longer'First
           and then Longer (Offset - 1) = '/'
           and then Longer (Offset .. Longer'Last) = Shorter;
      end Component_Suffix_Matches;
   begin
      if Normal_Path'Length = 0 or else Normal_Label'Length = 0 then
         return False;
      elsif Normal_Path = Normal_Label then
         return True;
      end if;

      return Component_Suffix_Matches (Normal_Path, Normal_Label)
        or else Component_Suffix_Matches (Normal_Label, Normal_Path);
   end Path_Matches_Label;

   function Has_Prefix (Text, Prefix : String) return Boolean is
   begin
      return Prefix'Length = 0
        or else (Text'Length >= Prefix'Length
                 and then Text (Text'First .. Text'First + Prefix'Length - 1) =
                   Prefix);
   end Has_Prefix;

   function Is_Identifier_Start (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z')
        or else (C >= 'a' and then C <= 'z');
   end Is_Identifier_Start;

   function Is_Identifier_Part (C : Character) return Boolean is
   begin
      return Is_Identifier_Start (C)
        or else (C >= '0' and then C <= '9')
        or else C = '_';
   end Is_Identifier_Part;

   function Is_Simple_Ada_Identifier (Name : String) return Boolean
   is
      Previous_Underscore : Boolean := False;
   begin
      if Name'Length = 0
        or else not Is_Identifier_Start (Name (Name'First))
        or else Editor.Syntax.Is_Keyword (Name)
      then
         return False;
      end if;

      for I in Name'Range loop
         if not Is_Identifier_Part (Name (I)) then
            return False;
         elsif Name (I) = '_' then
            if Previous_Underscore or else I = Name'Last then
               return False;
            end if;
            Previous_Underscore := True;
         else
            Previous_Underscore := False;
         end if;
      end loop;

      return True;
   end Is_Simple_Ada_Identifier;

   function Same_Buffer_Path
     (Key          : Editor.Ada_Project_Index.Indexed_File_Key;
      Path         : String;
      Buffer_Token : Natural) return Boolean is
   begin
      return Same_Path (To_String (Key.Path), Path)
        and then Key.Buffer_Token = Buffer_Token;
   end Same_Buffer_Path;

   function Same_Current_Key
     (Key                  : Editor.Ada_Project_Index.Indexed_File_Key;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean is
   begin
      return Same_Path (To_String (Key.Path), Path)
        and then Key.Buffer_Token = Buffer_Token
        and then Key.Buffer_Revision = Buffer_Revision
        and then Key.Lifecycle_Generation = Lifecycle_Generation
        and then Key.Fingerprint = Analysis_Fingerprint;
   end Same_Current_Key;

   function Preview_Rename
     (Service  : Service_State;
      Old_Name : String;
      New_Name : String) return Rename_Preview
   is
      Normal_Old : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Old_Name);
      Normal_New : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (New_Name);
      Result : Rename_Preview;
   begin
      Result.Old_Name := To_Unbounded_String (Old_Name);
      Result.New_Name := To_Unbounded_String (New_Name);

      if Normal_Old'Length = 0
        or else Normal_New'Length = 0
        or else Normal_Old = Normal_New
        or else not Is_Simple_Ada_Identifier (Old_Name)
        or else not Is_Simple_Ada_Identifier (New_Name)
      then
         Result.Status := Service_Unavailable;
         return Result;
      end if;

      declare
         Old_Matches : constant Language_Target_Set :=
           Find_References (Service, Old_Name);
         New_Matches : constant Language_Target_Set :=
           Find_References (Service, New_Name);
      begin
         if Old_Matches.Status = Service_Overflow
           or else New_Matches.Status = Service_Overflow
         then
            Result.Status := Service_Overflow;
            return Result;
         elsif Old_Matches.Targets.Is_Empty then
            Result.Status := Service_Unavailable;
            return Result;
         end if;

         Result.Edit_Count := Natural (Old_Matches.Targets.Length);
         Result.Conflict_Count := Natural (New_Matches.Targets.Length);
         Result.Edits := Old_Matches.Targets;
         Result.Conflicts := New_Matches.Targets;
         Result.Status :=
           (if Result.Conflict_Count = 0 then Service_Success
            else Service_Ambiguous);
      end;

      return Result;
   end Preview_Rename;

   function Request_Preview_Rename
     (Service  : in out Service_State;
      Id       : Semantic_Request_Id;
      Old_Name : String;
      New_Name : String) return Rename_Preview
   is
      Result : Rename_Preview;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Rename,
         Semantic_Request_Query_Key
           (Semantic_Request_Rename, Old_Name, Detail => New_Name))
      then
         return Rename_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Preview_Rename (Service, Old_Name, New_Name);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Preview_Rename;

   function Preview_Rename_Current
     (Service              : Service_State;
      Old_Name             : String;
      New_Name             : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Rename_Preview
   is
      Normal_Old : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Old_Name);
      Normal_New : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (New_Name);
      Result : Rename_Preview;
   begin
      Result.Old_Name := To_Unbounded_String (Old_Name);
      Result.New_Name := To_Unbounded_String (New_Name);

      if Normal_Old'Length = 0
        or else Normal_New'Length = 0
        or else Normal_Old = Normal_New
        or else not Is_Simple_Ada_Identifier (Old_Name)
        or else not Is_Simple_Ada_Identifier (New_Name)
      then
         Result.Status := Service_Unavailable;
         return Result;
      end if;

      declare
         Old_Matches : constant Language_Target_Set :=
           Find_Current_References
             (Service, Old_Name, Path, Buffer_Token, Buffer_Revision,
              Lifecycle_Generation, Analysis_Fingerprint);
         New_Matches : constant Language_Target_Set :=
           Find_References (Service, New_Name);
         Current_Conflicts : Language_Target_Vectors.Vector;
      begin
         if Old_Matches.Status = Service_Overflow
           or else New_Matches.Status = Service_Overflow
         then
            Result.Status := Service_Overflow;
            return Result;
         elsif Old_Matches.Status = Service_Stale then
            Result.Status := Service_Stale;
            return Result;
         elsif Old_Matches.Targets.Is_Empty then
            Result.Status := Service_Unavailable;
            return Result;
         end if;

         for Conflict of New_Matches.Targets loop
            if not Same_Buffer_Path (Conflict.Key, Path, Buffer_Token)
              or else Same_Current_Key
                (Conflict.Key, Path, Buffer_Token, Buffer_Revision,
                 Lifecycle_Generation, Analysis_Fingerprint)
            then
               Current_Conflicts.Append (Conflict);
            end if;
         end loop;

         Result.Edit_Count := Natural (Old_Matches.Targets.Length);
         Result.Conflict_Count := Natural (Current_Conflicts.Length);
         Result.Edits := Old_Matches.Targets;
         Result.Conflicts := Current_Conflicts;
         Result.Status :=
           (if Result.Conflict_Count = 0 then Service_Success
            else Service_Ambiguous);
      end;

      return Result;
   end Preview_Rename_Current;

   function Request_Preview_Rename_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Old_Name             : String;
      New_Name             : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Rename_Preview
   is
      Result : Rename_Preview;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Rename,
         Semantic_Current_Request_Query_Key
           (Semantic_Request_Rename, Old_Name, Path, Buffer_Token,
            Buffer_Revision, Lifecycle_Generation, Analysis_Fingerprint,
            Detail => New_Name))
      then
         return Rename_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Preview_Rename_Current
        (Service, Old_Name, New_Name, Path, Buffer_Token, Buffer_Revision,
         Lifecycle_Generation, Analysis_Fingerprint);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Preview_Rename_Current;


end Editor.Ada_Language_Service.Rename;
