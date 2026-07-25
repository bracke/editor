with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Characters.Handling;
with Ada.Strings.Fixed;
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

with Editor.Ada_Language_Service.Requests; use Editor.Ada_Language_Service.Requests;

package body Editor.Ada_Language_Service.Navigation is

   use type Editor.Ada_Language_Model.Symbol_Kind;

   Max_Service_Targets : constant Positive := 200;

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

   function Contains_Query (Text, Query : String) return Boolean is
      Normal_Text  : constant String := Editor.Ada_Language_Model.Normalize_Name (Text);
      Normal_Query : constant String := Editor.Ada_Language_Model.Normalize_Name (Query);
   begin
      if Normal_Query'Length = 0 then
         return True;
      end if;

      return Ada.Strings.Fixed.Index (Normal_Text, Normal_Query) /= 0;
   end Contains_Query;

   function To_Target
     (Symbol : Editor.Ada_Project_Index.Indexed_Symbol;
      Status : Service_Status := Service_Success) return Language_Target
   is
      Result : Language_Target;
   begin
      Result.Status := Status;
      Result.Target.Path := Symbol.Path;
      Result.Target.Line := Symbol.Symbol.Source_Span.Start_Line;
      Result.Target.Column := Symbol.Symbol.Source_Span.Start_Column;
      Result.Key := Symbol.Key;
      Result.Name := Symbol.Symbol.Name;
      Result.Detail := To_Unbounded_String
        (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label (Symbol));
      return Result;
   end To_Target;

   function Status_For
     (Result : Editor.Ada_Project_Index.Navigation_Candidate_Result)
      return Service_Status is
   begin
      case Result.Status is
         when Editor.Ada_Project_Index.Navigation_Target_Unique =>
            return Service_Success;
         when Editor.Ada_Project_Index.Navigation_Target_Ambiguous =>
            return Service_Ambiguous;
         when Editor.Ada_Project_Index.Navigation_Target_Overflow =>
            return Service_Overflow;
         when Editor.Ada_Project_Index.Navigation_Target_Unavailable =>
            return Service_Unavailable;
      end case;
   end Status_For;

   procedure Insert_Ordered
     (Targets : in out Language_Target_Vectors.Vector;
      Target  : Language_Target);

   function Candidate_Set_To_Target_Set
     (Candidates : Editor.Ada_Project_Index.Navigation_Candidate_Result)
      return Language_Target_Set
   is
      Result : Language_Target_Set;
   begin
      Result.Status := Status_For (Candidates);
      for C of Candidates.Candidates loop
         Insert_Ordered (Result.Targets, To_Target (C, Result.Status));
      end loop;
      return Result;
   end Candidate_Set_To_Target_Set;

   function Less (Left, Right : Language_Target) return Boolean
   is
      Left_Path   : constant String := To_String (Left.Target.Path);
      Right_Path  : constant String := To_String (Right.Target.Path);
      Left_Name   : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (To_String (Left.Name));
      Right_Name  : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (To_String (Right.Name));
   begin
      if Left_Path /= Right_Path then
         return Left_Path < Right_Path;
      elsif Left.Target.Line /= Right.Target.Line then
         return Left.Target.Line < Right.Target.Line;
      elsif Left.Target.Column /= Right.Target.Column then
         return Left.Target.Column < Right.Target.Column;
      else
         return Left_Name < Right_Name;
      end if;
   end Less;

   procedure Insert_Ordered
     (Targets : in out Language_Target_Vectors.Vector;
      Target  : Language_Target) is
   begin
      if Targets.Is_Empty then
         Targets.Append (Target);
         return;
      end if;

      for I in Targets.First_Index .. Targets.Last_Index loop
         if Less (Target, Targets (I)) then
            Targets.Insert (I, Target);
            return;
         end if;
      end loop;

      Targets.Append (Target);
   end Insert_Ordered;

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

   function Contains_Current
     (Service              : Service_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean is
   begin
      return Editor.Ada_Project_Index.Contains_Current
        (Service.Index, Path, Buffer_Token, Buffer_Revision,
         Lifecycle_Generation, Analysis_Fingerprint);
   end Contains_Current;

   function Goto_Declaration
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind)
      return Language_Target
   is
      Result : constant Editor.Ada_Project_Index.Unique_Target_Result :=
        Editor.Ada_Project_Index.Resolve_Unique_Navigation_Target
          (Service.Index, Name, Kind, Want_Body => False,
           Accept_Generic_Package_Spec => True,
           Accept_Generic_Subprogram => True,
           Accept_Operator_Function => True);
   begin
      if Result.Overflow then
         return (Status => Service_Overflow, others => <>);
      elsif Result.Ambiguous then
         return (Status => Service_Ambiguous, others => <>);
      elsif not Result.Available then
         if Kind = Editor.Ada_Language_Model.Symbol_Unknown then
            declare
               Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
                 Editor.Ada_Project_Index.Resolve
                   (Service.Index, Name, Max_Matches => 2);
            begin
               if Matches.Overflow then
                  return (Status => Service_Overflow, others => <>);
               elsif Natural (Matches.Matches.Length) = 1 then
                  return To_Target
                    (Matches.Matches (Matches.Matches.First_Index));
               elsif not Matches.Matches.Is_Empty then
                  return (Status => Service_Ambiguous, others => <>);
               end if;
            end;
         end if;

         return (Status => Service_Unavailable, others => <>);
      end if;

      return To_Target (Result.Target);
   end Goto_Declaration;

   function Request_Goto_Declaration
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind)
      return Language_Target
   is
      Result : Language_Target;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Goto_Declaration,
         Semantic_Request_Query_Key
           (Semantic_Request_Goto_Declaration, Name,
            Detail => Editor.Ada_Language_Model.Symbol_Kind'Image (Kind)))
      then
         return Target_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Goto_Declaration (Service, Name, Kind);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Goto_Declaration;

   function Goto_Declaration_Current
     (Service              : Service_State;
      Name                 : String;
      Kind                 : Editor.Ada_Language_Model.Symbol_Kind;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target
   is
      Current_Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve_Current
          (Service.Index, Name, Path, Buffer_Token, Buffer_Revision,
           Lifecycle_Generation, Analysis_Fingerprint);
      Current_Snapshot_Available : constant Boolean :=
        Editor.Ada_Project_Index.Contains_Current
          (Service.Index, Path, Buffer_Token, Buffer_Revision,
           Lifecycle_Generation, Analysis_Fingerprint);
      Result : Language_Target;
      Seen   : Natural := 0;
      First  : Editor.Ada_Project_Index.Indexed_Symbol;
   begin
      if Current_Matches.Overflow then
         return (Status => Service_Overflow, others => <>);
      end if;

      for Match of Current_Matches.Matches loop
         if Kind = Editor.Ada_Language_Model.Symbol_Unknown
           or else Match.Symbol.Kind = Kind
         then
            Seen := Seen + 1;
            if Seen = 1 then
               First := Match;
            end if;
         end if;
      end loop;

      if Seen = 1 then
         return To_Target (First);
      elsif Seen > 1 then
         return (Status => Service_Ambiguous, others => <>);
      elsif Current_Snapshot_Available then
         return (Status => Service_Unavailable, others => <>);
      end if;

      declare
         Project_Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
           Editor.Ada_Project_Index.Resolve
             (Service.Index, Name, Max_Matches => Max_Service_Targets);
      begin
         if Project_Matches.Overflow then
            Result.Status := Service_Overflow;
         elsif Project_Matches.Matches.Is_Empty then
            Result.Status := Service_Unavailable;
         else
            Result.Status := Service_Unavailable;
            for Match of Project_Matches.Matches loop
               if Same_Buffer_Path (Match.Key, Path, Buffer_Token)
               then
                  Result.Status := Service_Stale;
                  exit;
               end if;
            end loop;
         end if;
      end;

      return Result;
   end Goto_Declaration_Current;

   function Request_Goto_Declaration_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Kind                 : Editor.Ada_Language_Model.Symbol_Kind;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target
   is
      Result : Language_Target;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Goto_Declaration,
         Semantic_Current_Request_Query_Key
           (Semantic_Request_Goto_Declaration, Name, Path, Buffer_Token,
            Buffer_Revision, Lifecycle_Generation, Analysis_Fingerprint,
            Detail => Editor.Ada_Language_Model.Symbol_Kind'Image (Kind)))
      then
         return Target_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Goto_Declaration_Current
        (Service, Name, Kind, Path, Buffer_Token, Buffer_Revision,
         Lifecycle_Generation, Analysis_Fingerprint);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Goto_Declaration_Current;

   function Goto_Body
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set is
   begin
      return Candidate_Set_To_Target_Set
        (Editor.Ada_Project_Index.Resolve_Navigation_Candidates
           (Service.Index, Name, Kind, Want_Body => True,
            Profile_Summary => Profile_Summary,
            Require_Profile => Profile_Summary'Length > 0,
            Accept_Generic_Package_Spec => True,
            Accept_Generic_Subprogram => True,
            Accept_Operator_Function => True));
   end Goto_Body;

   function Request_Goto_Body
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set
   is
      Result : Language_Target_Set;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Goto_Body,
         Semantic_Request_Query_Key
           (Semantic_Request_Goto_Body, Name, Profile_Summary,
            Detail => Editor.Ada_Language_Model.Symbol_Kind'Image (Kind)))
      then
         return Target_Set_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Goto_Body (Service, Name, Kind, Profile_Summary);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Goto_Body;

   function Goto_Spec
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set is
   begin
      if Kind = Editor.Ada_Language_Model.Symbol_Separate_Body then
         declare
            Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
              Editor.Ada_Project_Index.Resolve (Service.Index, Name);
            Related : Editor.Ada_Project_Index.Navigation_Candidate_Result;
            Result  : Language_Target_Set;
            Seen    : Natural := 0;
            Separate_Match : Editor.Ada_Project_Index.Indexed_Symbol;
         begin
            if Matches.Overflow then
               Result.Status := Service_Overflow;
               return Result;
            end if;

            for Match of Matches.Matches loop
               if Match.Symbol.Kind = Editor.Ada_Language_Model.Symbol_Separate_Body
               then
                  Seen := Seen + 1;
                  if Seen = 1 then
                     Separate_Match := Match;
                  end if;
               end if;
            end loop;

            if Seen = 0 then
               Result.Status := Service_Unavailable;
               return Result;
            elsif Seen > 1 then
               Result.Status := Service_Ambiguous;
               return Result;
            end if;

            Related := Editor.Ada_Project_Index.Resolve_Related_Unit_Candidates
              (Service.Index,
               Separate_Match,
               Want_Body => False);
            return Candidate_Set_To_Target_Set (Related);
         end;
      end if;

      return Candidate_Set_To_Target_Set
        (Editor.Ada_Project_Index.Resolve_Navigation_Candidates
           (Service.Index, Name, Kind, Want_Body => False,
            Profile_Summary => Profile_Summary,
            Require_Profile => Profile_Summary'Length > 0,
            Accept_Generic_Package_Spec => True,
            Accept_Generic_Subprogram => True,
            Accept_Operator_Function => True));
   end Goto_Spec;

   function Request_Goto_Spec
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set
   is
      Result : Language_Target_Set;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Goto_Spec,
         Semantic_Request_Query_Key
           (Semantic_Request_Goto_Spec, Name, Profile_Summary,
            Detail => Editor.Ada_Language_Model.Symbol_Kind'Image (Kind)))
      then
         return Target_Set_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Goto_Spec (Service, Name, Kind, Profile_Summary);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Goto_Spec;

   function Find_References
     (Service : Service_State;
      Name    : String) return Language_Target_Set
   is
      Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve
          (Service.Index, Name, Max_Matches => Max_Service_Targets);
      Result  : Language_Target_Set;
   begin
      if Matches.Overflow then
         Result.Status := Service_Overflow;
         return Result;
      elsif Matches.Matches.Is_Empty then
         Result.Status := Service_Unavailable;
         return Result;
      end if;

      Result.Status := Service_Success;
      for Match of Matches.Matches loop
         Insert_Ordered (Result.Targets, To_Target (Match, Result.Status));
      end loop;
      return Result;
   end Find_References;

   function Request_Find_References
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String) return Language_Target_Set
   is
      Result : Language_Target_Set;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Find_References, Name)
      then
         return Target_Set_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Find_References (Service, Name);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Find_References;

   function Find_Current_References
     (Service              : Service_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target_Set
   is
      Current_Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve_Current
          (Service.Index, Name, Path, Buffer_Token, Buffer_Revision,
           Lifecycle_Generation, Analysis_Fingerprint);
      Current_Snapshot_Available : constant Boolean :=
        Editor.Ada_Project_Index.Contains_Current
          (Service.Index, Path, Buffer_Token, Buffer_Revision,
           Lifecycle_Generation, Analysis_Fingerprint);
      Project_Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve
          (Service.Index, Name, Max_Matches => Max_Service_Targets);
      Result : Language_Target_Set;
   begin
      if Current_Matches.Overflow then
         Result.Status := Service_Overflow;
         return Result;
      elsif Project_Matches.Overflow then
         Result.Status := Service_Overflow;
         return Result;
      elsif not Current_Matches.Matches.Is_Empty then
         Result.Status := Service_Success;
         for Match of Project_Matches.Matches loop
            if not Same_Buffer_Path (Match.Key, Path, Buffer_Token)
              or else Same_Current_Key
                (Match.Key, Path, Buffer_Token, Buffer_Revision,
                 Lifecycle_Generation, Analysis_Fingerprint)
            then
               Insert_Ordered (Result.Targets, To_Target (Match, Result.Status));
            end if;
         end loop;
         return Result;
      elsif Current_Snapshot_Available then
         Result.Status := Service_Unavailable;
         return Result;
      end if;

      if Project_Matches.Matches.Is_Empty then
         Result.Status := Service_Unavailable;
      else
         Result.Status := Service_Unavailable;
         for Match of Project_Matches.Matches loop
            if Same_Buffer_Path (Match.Key, Path, Buffer_Token)
            then
               Result.Status := Service_Stale;
               exit;
            end if;
         end loop;
      end if;

      return Result;
   end Find_Current_References;

   function Request_Find_Current_References
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target_Set
   is
      Result : Language_Target_Set;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Find_References,
         Semantic_Current_Request_Query_Key
           (Semantic_Request_Find_References, Name, Path, Buffer_Token,
            Buffer_Revision, Lifecycle_Generation, Analysis_Fingerprint))
      then
         return Target_Set_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Find_Current_References
        (Service, Name, Path, Buffer_Token, Buffer_Revision,
         Lifecycle_Generation, Analysis_Fingerprint);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Find_Current_References;

   function Workspace_Symbols
     (Service : Service_State;
      Query   : String := "") return Language_Target_Set
   is
      Result : Language_Target_Set;

      function Less_By_Name (Left, Right : Language_Target) return Boolean
      is
         Left_Name  : constant String :=
           Editor.Ada_Language_Model.Normalize_Name (To_String (Left.Name));
         Right_Name : constant String :=
           Editor.Ada_Language_Model.Normalize_Name (To_String (Right.Name));
      begin
         if Left_Name /= Right_Name then
            return Left_Name < Right_Name;
         else
            return Less (Left, Right);
         end if;
      end Less_By_Name;

      procedure Insert_Workspace_Ordered (Target : Language_Target) is
      begin
         if Result.Targets.Is_Empty then
            Result.Targets.Append (Target);
            return;
         end if;

         for I in Result.Targets.First_Index .. Result.Targets.Last_Index loop
            if Less_By_Name (Target, Result.Targets (I)) then
               Result.Targets.Insert (I, Target);
               return;
            end if;
         end loop;

         Result.Targets.Append (Target);
      end Insert_Workspace_Ordered;
   begin
      if Editor.Ada_Project_Index.Overflowed (Service.Index) then
         Result.Status := Service_Overflow;
         return Result;
      else
         Result.Status := Service_Unavailable;
      end if;

      for F in 1 .. Editor.Ada_Project_Index.File_Count (Service.Index) loop
         declare
            Key : constant Editor.Ada_Project_Index.Indexed_File_Key :=
              Editor.Ada_Project_Index.File_Key_At (Service.Index, F);
            Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
              Editor.Ada_Project_Index.File_Analysis_At (Service.Index, F);
         begin
            for S in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
               declare
                  Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
                    Editor.Ada_Language_Model.Symbol_At (Analysis, S);
               begin
                  if Contains_Query (To_String (Symbol.Name), Query) then
                     if Natural (Result.Targets.Length) >= Max_Service_Targets then
                        Result.Targets.Clear;
                        Result.Status := Service_Overflow;
                        return Result;
                     end if;

                     Insert_Workspace_Ordered
                       (To_Target ((Path => Key.Path,
                                    Key => Key,
                                    Symbol => Symbol),
                                   Service_Success));
                     Result.Status := Service_Success;
                  end if;
               end;
            end loop;
         end;
      end loop;

      return Result;
   end Workspace_Symbols;

   function Request_Workspace_Symbols
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Query   : String := "") return Language_Target_Set
   is
      Result : Language_Target_Set;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Workspace_Symbols, Query)
      then
         return Target_Set_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Workspace_Symbols (Service, Query);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Workspace_Symbols;

end Editor.Ada_Language_Service.Navigation;
