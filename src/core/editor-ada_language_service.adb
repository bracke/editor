with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Action_Router;
with Editor.Ada_Diagnostic_Navigation;
with Editor.Ada_Diagnostic_Panel_Projection;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Diagnostic_Status_Line;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Syntax;

package body Editor.Ada_Language_Service is

   use type Editor.Ada_Language_Model.Symbol_Kind;

   Max_Service_Targets : constant Positive := 200;

   function Mix (Left : Natural; Right : Natural) return Natural is
      Modulus : constant Natural := 1_000_003;
   begin
      return
        (((Left mod Modulus) * 131)
         + (Right mod Modulus)
         + 16#9E37#) mod Modulus;
   end Mix;

   function Text_Fingerprint (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for Ch of Text loop
         Result := Mix (Result, Character'Pos (Ch) + 1);
      end loop;
      return Result;
   end Text_Fingerprint;

   function Diagnostic_Fingerprint
     (Diagnostic : Compiler_Diagnostic) return Natural
   is
      Result : Natural := 17;
   begin
      Result := Mix
        (Result,
         Editor.External_Producers.Compiler_Diagnostic_Severity'Pos
           (Diagnostic.Severity) + 1);
      Result := Mix (Result, Text_Fingerprint (To_String (Diagnostic.File_Label)));
      Result := Mix (Result, Text_Fingerprint (To_String (Diagnostic.Message)));
      Result := Mix (Result, Boolean'Pos (Diagnostic.Has_Location) + 1);
      Result := Mix (Result, Diagnostic.Line + 1);
      Result := Mix (Result, Diagnostic.Column + 1);
      Result := Mix (Result, Text_Fingerprint (To_String (Diagnostic.Tool_Name)));
      return Result;
   end Diagnostic_Fingerprint;

   function Diagnostic_Fingerprint
     (Diagnostic : Semantic_Diagnostic) return Natural
   is
      Result : Natural := 23;
   begin
      Result := Mix
        (Result,
         Semantic_Diagnostic_Severity'Pos (Diagnostic.Severity) + 1);
      Result := Mix (Result, Text_Fingerprint (To_String (Diagnostic.Path)));
      Result := Mix (Result, Text_Fingerprint (To_String (Diagnostic.Message)));
      Result := Mix (Result, Boolean'Pos (Diagnostic.Has_Location) + 1);
      Result := Mix (Result, Diagnostic.Line + 1);
      Result := Mix (Result, Diagnostic.Column + 1);
      Result := Mix (Result, Text_Fingerprint (To_String (Diagnostic.Source)));
      return Result;
   end Diagnostic_Fingerprint;

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
      Normal_Text  : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Text);
      Normal_Query : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Query);
   begin
      if Normal_Query'Length = 0 then
         return True;
      end if;

      return Ada.Strings.Unbounded.Index
        (To_Unbounded_String (Normal_Text), Normal_Query) > 0;
   end Contains_Query;

   procedure Count_Semantic_Severity
     (Status   : in out Semantic_Diagnostic_Status;
      Severity : Semantic_Diagnostic_Severity)
   is
   begin
      case Severity is
         when Semantic_Error =>
            Status.Error_Count := Status.Error_Count + 1;
         when Semantic_Warning =>
            Status.Warning_Count := Status.Warning_Count + 1;
         when Semantic_Info =>
            Status.Info_Count := Status.Info_Count + 1;
         when Semantic_Hint =>
            Status.Hint_Count := Status.Hint_Count + 1;
      end case;
   end Count_Semantic_Severity;

   procedure Count_Compiler_Severity
     (Status   : in out Compiler_Backend_Status;
      Severity : Compiler_Diagnostic_Severity)
   is
   begin
      case Severity is
         when Editor.External_Producers.Compiler_Error
            | Editor.External_Producers.Compiler_Fatal =>
            Status.Error_Count := Status.Error_Count + 1;
         when Editor.External_Producers.Compiler_Warning =>
            Status.Warning_Count := Status.Warning_Count + 1;
         when Editor.External_Producers.Compiler_Info =>
            Status.Info_Count := Status.Info_Count + 1;
         when Editor.External_Producers.Compiler_Note =>
            Status.Note_Count := Status.Note_Count + 1;
         when Editor.External_Producers.Compiler_Unknown =>
            Status.Unknown_Count := Status.Unknown_Count + 1;
      end case;
   end Count_Compiler_Severity;

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

   procedure Recompute_Semantic_State (Service : in out Service_State) is
   begin
      Service.Semantic_State := (others => <>);
      for Diagnostic of Service.Semantic_Diagnostics loop
         Count_Semantic_Severity (Service.Semantic_State, Diagnostic.Severity);
         Service.Semantic_State.Diagnostic_Count :=
           Service.Semantic_State.Diagnostic_Count + 1;
         Service.Semantic_State.Fingerprint := Mix
           (Service.Semantic_State.Fingerprint,
            Diagnostic_Fingerprint (Diagnostic));
      end loop;
   end Recompute_Semantic_State;

   procedure Clear_Semantic_Diagnostics_By_Source_Prefix
     (Service       : in out Service_State;
      Path          : String;
      Source_Prefix : String)
   is
      Kept : Semantic_Diagnostic_Vectors.Vector;
   begin
      for Diagnostic of Service.Semantic_Diagnostics loop
         if Path_Matches_Label (Path, To_String (Diagnostic.Path))
           and then Has_Prefix (To_String (Diagnostic.Source), Source_Prefix)
         then
            null;
         else
            Kept.Append (Diagnostic);
         end if;
      end loop;

      Service.Semantic_Diagnostics := Kept;
      Recompute_Semantic_State (Service);
   end Clear_Semantic_Diagnostics_By_Source_Prefix;

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

   procedure Clear (Service : in out Service_State) is
   begin
      Editor.Ada_Project_Index.Clear (Service.Index);
      Clear_Semantic_Diagnostics (Service);
      Clear_Compiler_Backend (Service);
      Service.Next_Request_Id := No_Semantic_Request;
      Service.Active_Request := (others => <>);
      Service.Previous_Request := (others => <>);
   end Clear;

   function From_Index
     (Index : Editor.Ada_Project_Index.Index_State) return Service_State is
   begin
      return
        (Index                => Index,
        Semantic_Diagnostics => Semantic_Diagnostic_Vectors.Empty_Vector,
        Semantic_State       => (others => <>),
         Compiler_Diagnostics => Compiler_Diagnostic_Vectors.Empty_Vector,
         Compiler_State       => (others => <>),
         Next_Request_Id      => No_Semantic_Request,
         Active_Request       => (others => <>),
         Previous_Request     => (others => <>));
   end From_Index;

   procedure Put_Index
     (Service : in out Service_State;
      Index   : Editor.Ada_Project_Index.Index_State) is
      Old_Fingerprint : constant Natural :=
        Editor.Ada_Project_Index.Fingerprint (Service.Index);
      New_Fingerprint : constant Natural :=
        Editor.Ada_Project_Index.Fingerprint (Index);
   begin
      Service.Index := Index;
      if Service.Active_Request.Status = Semantic_Request_Pending
        and then Old_Fingerprint /= New_Fingerprint
      then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Put_Index;

   function Project_Index
     (Service : Service_State) return Editor.Ada_Project_Index.Index_State is
   begin
      return Service.Index;
   end Project_Index;

   procedure Put_Buffer_Analysis
     (Service              : in out Service_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis             : Editor.Ada_Language_Model.Analysis_Result) is
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Service.Index, Path, Buffer_Token, Buffer_Revision,
         Lifecycle_Generation, Analysis);
      if Service.Active_Request.Status = Semantic_Request_Pending
        and then Service.Active_Request.Index_Fingerprint /=
          Editor.Ada_Project_Index.Fingerprint (Service.Index)
      then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Put_Buffer_Analysis;

   procedure Invalidate_Path (Service : in out Service_State; Path : String) is
   begin
      Editor.Ada_Project_Index.Invalidate_Path (Service.Index, Path);
      if Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Invalidate_Path;

   procedure Invalidate_Path_Subtree
     (Service : in out Service_State;
      Root_Path : String) is
   begin
      Editor.Ada_Project_Index.Invalidate_Path_Subtree
        (Service.Index, Root_Path);
      if Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Invalidate_Path_Subtree;

   procedure Invalidate_Buffer
     (Service : in out Service_State;
      Buffer_Token : Natural) is
   begin
      Editor.Ada_Project_Index.Invalidate_Buffer (Service.Index, Buffer_Token);
      if Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Invalidate_Buffer;

   procedure Invalidate_Lifecycle
     (Service : in out Service_State;
      Lifecycle_Generation : Natural) is
   begin
      Editor.Ada_Project_Index.Invalidate_Lifecycle
        (Service.Index, Lifecycle_Generation);
      if Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Invalidate_Lifecycle;

   function Status (Service : Service_State) return Index_Status is
   begin
      return
        (File_Count   => Editor.Ada_Project_Index.File_Count (Service.Index),
         Unit_Count   => Editor.Ada_Project_Index.Unit_Count (Service.Index),
         Symbol_Count => Editor.Ada_Project_Index.Symbol_Count (Service.Index),
         Fingerprint  => Editor.Ada_Project_Index.Fingerprint (Service.Index),
         Overflowed   => Editor.Ada_Project_Index.Overflowed (Service.Index));
   end Status;

   function Status
     (Index : Editor.Ada_Project_Index.Index_State) return Index_Status is
   begin
      return Status (From_Index (Index));
   end Status;

   function Semantic_Request_Query_Key
     (Kind            : Semantic_Request_Kind;
      Name            : String;
      Profile_Summary : String := "";
      Detail          : String := "") return String
   is
      Separator : constant Character := Character'Val (31);
   begin
      case Kind is
         when Semantic_Request_Goto_Declaration =>
            if Detail'Length > 0 then
               return Name & Separator & Detail;
            end if;
         when Semantic_Request_Goto_Body | Semantic_Request_Goto_Spec =>
            if Profile_Summary'Length > 0 or else Detail'Length > 0 then
               return Name & Separator & Profile_Summary &
                 Separator & Detail;
            end if;
         when Semantic_Request_Completion | Semantic_Request_Rename =>
            if Detail'Length > 0 then
               return Name & Separator & Detail;
            end if;
         when others =>
            null;
      end case;

      return Name;
   end Semantic_Request_Query_Key;

   function Semantic_Current_Request_Query_Key
     (Kind                 : Semantic_Request_Kind;
      Query                : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Detail               : String := "") return String
   is
      Separator : constant Character := Character'Val (30);
   begin
      return Semantic_Request_Kind'Image (Kind) &
        Separator & Query &
        Separator & Path &
        Separator & Natural'Image (Buffer_Token) &
        Separator & Natural'Image (Buffer_Revision) &
        Separator & Natural'Image (Lifecycle_Generation) &
        Separator & Natural'Image (Analysis_Fingerprint) &
        Separator & Detail;
   end Semantic_Current_Request_Query_Key;

   function Begin_Semantic_Request
     (Service : in out Service_State;
      Kind    : Semantic_Request_Kind;
      Query   : String := "") return Semantic_Request_Id
   is
   begin
      Service.Previous_Request := Service.Active_Request;
      if Service.Previous_Request.Status = Semantic_Request_Pending then
         Service.Previous_Request.Status := Semantic_Request_Superseded;
         Service.Previous_Request.Result_Status := Service_Stale;
      end if;

      if Service.Next_Request_Id = Semantic_Request_Id'Last then
         Service.Next_Request_Id := 1;
      else
         Service.Next_Request_Id := Service.Next_Request_Id + 1;
      end if;

      Service.Active_Request :=
        (Id                => Service.Next_Request_Id,
         Kind              => Kind,
         Status            => Semantic_Request_Pending,
         Query             => To_Unbounded_String (Query),
         Index_Fingerprint => Editor.Ada_Project_Index.Fingerprint
           (Service.Index),
         Result_Status     => Service_Unavailable);
      return Service.Active_Request.Id;
   end Begin_Semantic_Request;

   procedure Cancel_Semantic_Request
     (Service : in out Service_State;
      Id      : Semantic_Request_Id) is
   begin
      if Id /= No_Semantic_Request
        and then Service.Active_Request.Id = Id
        and then Service.Active_Request.Status = Semantic_Request_Pending
      then
         Service.Active_Request.Status := Semantic_Request_Cancelled;
         Service.Active_Request.Result_Status := Service_Unavailable;
      end if;
   end Cancel_Semantic_Request;

   function Active_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status is
   begin
      return Service.Active_Request;
   end Active_Semantic_Request;

   function Previous_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status is
   begin
      return Service.Previous_Request;
   end Previous_Semantic_Request;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id) return Boolean is
   begin
      return Id /= No_Semantic_Request
        and then Service.Active_Request.Id = Id
        and then Service.Active_Request.Status = Semantic_Request_Pending
        and then Service.Active_Request.Index_Fingerprint =
          Editor.Ada_Project_Index.Fingerprint (Service.Index);
   end Semantic_Request_Is_Current;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind) return Boolean is
   begin
      return Semantic_Request_Is_Current (Service, Id)
        and then Service.Active_Request.Kind = Kind;
   end Semantic_Request_Is_Current;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind;
      Query   : String) return Boolean
   is
      Active_Query : constant String := To_String (Service.Active_Request.Query);
   begin
      return Semantic_Request_Is_Current (Service, Id, Kind)
        and then Active_Query = Query;
   end Semantic_Request_Is_Current;

   function Request_Rejected_Status
     (Service : Service_State;
      Id      : Semantic_Request_Id) return Service_Status
   is
   begin
      if Id = No_Semantic_Request
        or else Service.Active_Request.Id /= Id
        or else Service.Active_Request.Status = Semantic_Request_No_Request
      then
         return Service_Unavailable;
      elsif Service.Active_Request.Status = Semantic_Request_Cancelled then
         return Service_Unavailable;
      else
         return Service_Stale;
      end if;
   end Request_Rejected_Status;

   procedure Finish_Semantic_Request
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Status  : Service_Status)
   is
   begin
      if Id = No_Semantic_Request
        or else Service.Active_Request.Id /= Id
      then
         return;
      elsif Service.Active_Request.Status = Semantic_Request_Pending
        and then Service.Active_Request.Index_Fingerprint =
          Editor.Ada_Project_Index.Fingerprint (Service.Index)
      then
         Service.Active_Request.Status := Semantic_Request_Completed;
         Service.Active_Request.Result_Status := Status;
      elsif Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Finish_Semantic_Request;

   function Backend_Status
     (Service : Service_State) return Semantic_Backend_Status
   is
      Index_State : constant Index_Status := Status (Service);
      Semantic    : constant Semantic_Diagnostic_Status :=
        Service.Semantic_State;
      Compiler    : constant Compiler_Backend_Status :=
        Service.Compiler_State;
      Result      : Semantic_Backend_Status;
   begin
      Result.Internal_Index_Available :=
        Index_State.File_Count > 0 or else Index_State.Symbol_Count > 0;
      Result.Internal_Diagnostics_Active := Semantic.Diagnostic_Count > 0;
      Result.Compiler_Diagnostics_Active := Compiler.Diagnostic_Count > 0;
      Result.Compiler_Backend_Available := Compiler.Has_Run;
      Result.Navigation_From_Index := Result.Internal_Index_Available;
      Result.Diagnostics_From_Internal := Result.Internal_Diagnostics_Active;
      Result.Diagnostics_From_Compiler := Result.Compiler_Diagnostics_Active;
      Result.Semantic_Requests_Available := True;
      Result.Semantic_Requests_Cancellable :=
        Service.Active_Request.Status = Semantic_Request_Pending;
      Result.Active_Request_Id := Service.Active_Request.Id;
      Result.Active_Request_Kind := Service.Active_Request.Kind;
      Result.Active_Request_Status := Service.Active_Request.Status;
      Result.Previous_Request_Status := Service.Previous_Request.Status;

      if Result.Compiler_Diagnostics_Active then
         Result.Active_Backend := Semantic_Backend_GNAT_Compiler;
      else
         Result.Active_Backend := Semantic_Backend_Internal_Index;
      end if;

      Result.Fingerprint := Mix (Index_State.Fingerprint, Semantic.Fingerprint);
      Result.Fingerprint := Mix (Result.Fingerprint, Compiler.Fingerprint);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Semantic_Backend_Kind'Pos (Result.Active_Backend) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Internal_Index_Available) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Internal_Diagnostics_Active) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Compiler_Backend_Available) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Compiler_Diagnostics_Active) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Diagnostics_From_Internal) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Diagnostics_From_Compiler) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Semantic_Requests_Available) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Semantic_Requests_Cancellable) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint, Result.Active_Request_Id + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Semantic_Request_Kind'Pos (Result.Active_Request_Kind) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Semantic_Request_Status_Kind'Pos (Result.Active_Request_Status) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Semantic_Request_Status_Kind'Pos (Result.Previous_Request_Status) + 1);
      return Result;
   end Backend_Status;

   function Backend_Label
     (Status : Semantic_Backend_Status) return String
   is
   begin
      case Status.Active_Backend is
         when Semantic_Backend_Internal_Index =>
            return "internal-index";
         when Semantic_Backend_GNAT_Compiler =>
            return "gnat-compiler";
      end case;
   end Backend_Label;

   function Capabilities
     (Service : Service_State) return Language_Service_Capabilities
   is
      Backend : constant Semantic_Backend_Status := Backend_Status (Service);
      Result  : Language_Service_Capabilities;
      Index_Ready : constant Boolean :=
        Backend.Navigation_From_Index
        and then Editor.Ada_Project_Index.Symbol_Count (Service.Index) > 0;
   begin
      Result.Navigation_Ready := Index_Ready;
      Result.References_Ready := Index_Ready;
      Result.Workspace_Symbols_Ready := Index_Ready;
      Result.Completion_Ready := Index_Ready;
      Result.Hover_Ready := Index_Ready;
      Result.Rename_Preview_Ready := Index_Ready;
      Result.Internal_Diagnostics_Ready :=
        Backend.Diagnostics_From_Internal;
      Result.Compiler_Diagnostics_Ready :=
        Backend.Diagnostics_From_Compiler;
      Result.Request_Cancellation_Available :=
        Backend.Semantic_Requests_Cancellable;

      Result.Fingerprint := Backend.Fingerprint;
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Navigation_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Navigation_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.References_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.References_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Workspace_Symbols_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Workspace_Symbols_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Completion_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Completion_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Hover_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Hover_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Rename_Preview_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Rename_Preview_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Diagnostics_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Internal_Diagnostics_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Compiler_Diagnostics_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Request_Lifecycle_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Request_Cancellation_Available) + 1);
      return Result;
   end Capabilities;

   procedure Clear_Semantic_Diagnostics (Service : in out Service_State) is
   begin
      Service.Semantic_Diagnostics.Clear;
      Service.Semantic_State := (others => <>);
   end Clear_Semantic_Diagnostics;

   procedure Put_Semantic_Diagnostic
     (Service    : in out Service_State;
      Diagnostic : Semantic_Diagnostic)
   is
   begin
      Count_Semantic_Severity (Service.Semantic_State, Diagnostic.Severity);

      if Natural (Service.Semantic_Diagnostics.Length) <
        Max_Semantic_Diagnostics
      then
         Service.Semantic_Diagnostics.Append (Diagnostic);
         Service.Semantic_State.Diagnostic_Count :=
           Natural (Service.Semantic_Diagnostics.Length);
         Service.Semantic_State.Fingerprint := Mix
           (Service.Semantic_State.Fingerprint,
            Diagnostic_Fingerprint (Diagnostic));
      else
         Service.Semantic_State.Overflowed := True;
         Service.Semantic_State.Fingerprint := Mix
           (Service.Semantic_State.Fingerprint, 16#5EAD#);
      end if;
   end Put_Semantic_Diagnostic;

   function To_Service_Severity
     (Severity :
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity)
      return Semantic_Diagnostic_Severity is
   begin
      case Severity is
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
            return Semantic_Error;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
            return Semantic_Warning;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
            return Semantic_Info;
      end case;
   end To_Service_Severity;

   procedure Put_Semantic_Diagnostic_Feed
     (Service      : in out Service_State;
      Path         : String;
      Feed         : Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model;
      Source_Label : String := "semantic-feed")
   is
      package Feed_Pkg renames Editor.Ada_Semantic_Diagnostic_Feed;
      package Index_Pkg renames Editor.Ada_Semantic_Diagnostic_Index;
      package Command_Pkg renames Editor.Ada_Diagnostic_Command_Projection;
   begin
      Clear_Semantic_Diagnostics_By_Source_Prefix
        (Service, Path, Source_Label & ":");

      if not Feed_Pkg.Current (Feed) then
         Service.Semantic_State.Fingerprint :=
           Mix (Text_Fingerprint (Path), Feed_Pkg.Fingerprint (Feed));
         Service.Semantic_State.Fingerprint :=
           Mix (Service.Semantic_State.Fingerprint,
                Feed_Pkg.Rejected_Entry_Count (Feed) + 1);
         return;
      end if;

      Service.Semantic_State.Fingerprint :=
        Mix (Text_Fingerprint (Path), Feed_Pkg.Fingerprint (Feed));

      declare
         Index : constant Index_Pkg.Semantic_Diagnostic_Index_Model :=
           Index_Pkg.Build (Feed);
         Quick_Fixes : constant
           Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model :=
           Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Build (Index);
         Navigation : constant
           Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model :=
           Editor.Ada_Diagnostic_Navigation.Build (Index);
         Panel : constant
           Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model :=
           Editor.Ada_Diagnostic_Panel_Projection.Build (Index, Path);
         Provenance : constant
           Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model :=
           Editor.Ada_Diagnostic_Provenance.Build (Index);
         Status_Line : constant
           Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model :=
           Editor.Ada_Diagnostic_Status_Line.Build (Index);
         Routes : constant
           Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Router_Model :=
           Editor.Ada_Diagnostic_Action_Router.Build
             (Quick_Fixes, Navigation, Panel, Provenance, Status_Line);
         Commands : constant Command_Pkg.Diagnostic_Command_Projection_Model :=
           Command_Pkg.Build (Routes);
      begin
      for I in 1 .. Feed_Pkg.Entry_Count (Feed) loop
         declare
            Feed_Item : constant Feed_Pkg.Semantic_Diagnostic_Feed_Entry :=
              Feed_Pkg.Entry_At (Feed, I);
            Index_Id : Index_Pkg.Semantic_Diagnostic_Index_Id :=
              Index_Pkg.No_Semantic_Diagnostic_Index_Entry;
            Descriptor : Command_Pkg.Diagnostic_Command_Descriptor :=
              Command_Pkg.First_For_Diagnostic (Commands, Index_Id);
         begin
            for J in 1 .. Index_Pkg.Entry_Count (Index) loop
               declare
                  Indexed : constant Index_Pkg.Semantic_Diagnostic_Index_Entry :=
                    Index_Pkg.Entry_At (Index, J);
               begin
                  if Indexed.Feed_Index = I then
                     Index_Id := Indexed.Id;
                     exit;
                  end if;
               end;
            end loop;

            Descriptor := Command_Pkg.First_For_Diagnostic (Commands, Index_Id);
            Put_Semantic_Diagnostic
              (Service,
               (Severity     => To_Service_Severity (Feed_Item.Severity),
                Message      => Feed_Item.Message,
                Path         => To_Unbounded_String (Path),
                Has_Location => True,
                Line         => Feed_Item.Start_Line,
                Column       => Feed_Item.Start_Column,
                Source       => To_Unbounded_String (Source_Label & ":" &
                  Feed_Pkg.Semantic_Diagnostic_Feed_Source'Image
                    (Feed_Item.Source)),
                Has_Command_Descriptor => Command_Pkg.Has_Descriptor (Descriptor),
                Command_Descriptor     => Descriptor));
         end;
      end loop;
      end;
   end Put_Semantic_Diagnostic_Feed;

   function Semantic_Diagnostics_Status
     (Service : Service_State) return Semantic_Diagnostic_Status is
   begin
      return Service.Semantic_State;
   end Semantic_Diagnostics_Status;

   function Semantic_Diagnostics_Status_For_Path
     (Service : Service_State;
      Path    : String) return Semantic_Diagnostic_Status
   is
      Result : Semantic_Diagnostic_Status;
   begin
      Result.Overflowed := Service.Semantic_State.Overflowed;
      Result.Fingerprint := Mix
        (Service.Semantic_State.Fingerprint, Text_Fingerprint (Path));

      for Diagnostic of Service.Semantic_Diagnostics loop
         if Path_Matches_Label (Path, To_String (Diagnostic.Path)) then
            Result.Diagnostic_Count := Result.Diagnostic_Count + 1;
            Count_Semantic_Severity (Result, Diagnostic.Severity);
            Result.Fingerprint := Mix
              (Result.Fingerprint, Diagnostic_Fingerprint (Diagnostic));
         end if;
      end loop;

      return Result;
   end Semantic_Diagnostics_Status_For_Path;

   function Semantic_Diagnostic_Count
     (Service : Service_State) return Natural is
   begin
      return Natural (Service.Semantic_Diagnostics.Length);
   end Semantic_Diagnostic_Count;

   function Semantic_Diagnostic_At
     (Service : Service_State;
      Index   : Positive) return Semantic_Diagnostic is
   begin
      if Index > Natural (Service.Semantic_Diagnostics.Length) then
         return (others => <>);
      end if;

      return Service.Semantic_Diagnostics.Element (Index);
   end Semantic_Diagnostic_At;

   function Semantic_Diagnostic_Count_For_Path
     (Service : Service_State;
      Path    : String) return Natural is
   begin
      return Semantic_Diagnostics_Status_For_Path
        (Service, Path).Diagnostic_Count;
   end Semantic_Diagnostic_Count_For_Path;

   function Semantic_Diagnostic_At_For_Path
     (Service : Service_State;
      Path    : String;
      Index   : Positive) return Semantic_Diagnostic
   is
      Seen : Natural := 0;
   begin
      for Diagnostic of Service.Semantic_Diagnostics loop
         if Path_Matches_Label (Path, To_String (Diagnostic.Path)) then
            Seen := Seen + 1;
            if Seen = Index then
               return Diagnostic;
            end if;
         end if;
      end loop;

      return (others => <>);
   end Semantic_Diagnostic_At_For_Path;

   procedure Clear_Compiler_Backend (Service : in out Service_State) is
   begin
      Service.Compiler_Diagnostics.Clear;
      Service.Compiler_State := (others => <>);
   end Clear_Compiler_Backend;

   procedure Put_Compiler_Diagnostic_Lines
     (Service         : in out Service_State;
      Lines           : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Tool_Name       : String := "gnat";
      Run_Fingerprint : Natural := 0)
   is
      Parsed : constant Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Lines
          (Lines, Tool_Name);
      State : Compiler_Backend_Status;
   begin
      Service.Compiler_Diagnostics.Clear;

      State.Has_Run := True;
      State.Input_Count := Parsed.Input_Count;
      State.Accepted_Count := Parsed.Accepted_Count;
      State.Rejected_Malformed_Count := Parsed.Rejected_Malformed_Count;
      State.Fingerprint := Mix
        (Run_Fingerprint,
         Text_Fingerprint (Tool_Name));
      State.Fingerprint := Mix (State.Fingerprint, Parsed.Input_Count + 1);
      State.Fingerprint := Mix (State.Fingerprint, Parsed.Accepted_Count + 1);
      State.Fingerprint := Mix
        (State.Fingerprint, Parsed.Rejected_Malformed_Count + 1);

      for R of Parsed.Records loop
         declare
            Diagnostic : constant Compiler_Diagnostic :=
              (Severity     => R.Severity,
               Message      => R.Message,
               File_Label   => R.File_Label,
               Has_Location => R.Has_Location,
               Line         => R.Line,
               Column       => R.Column,
               Tool_Name    => R.Tool_Name);
         begin
            Count_Compiler_Severity (State, Diagnostic.Severity);
            if Natural (Service.Compiler_Diagnostics.Length) <
              Max_Compiler_Diagnostics
            then
               Service.Compiler_Diagnostics.Append (Diagnostic);
               State.Fingerprint := Mix
                 (State.Fingerprint, Diagnostic_Fingerprint (Diagnostic));
            else
               State.Overflowed := True;
               State.Fingerprint := Mix (State.Fingerprint, 16#C011#);
            end if;
         end;
      end loop;

      State.Diagnostic_Count :=
        Natural (Service.Compiler_Diagnostics.Length);
      Service.Compiler_State := State;
   end Put_Compiler_Diagnostic_Lines;

   function Compiler_Status
     (Service : Service_State) return Compiler_Backend_Status is
   begin
      return Service.Compiler_State;
   end Compiler_Status;

   function Compiler_Status_For_Path
     (Service : Service_State;
      Path    : String) return Compiler_Backend_Status
   is
      Result : Compiler_Backend_Status;
   begin
      Result.Has_Run := Service.Compiler_State.Has_Run;
      if not Result.Has_Run then
         return Result;
      end if;

      Result.Input_Count := Service.Compiler_State.Input_Count;
      Result.Overflowed := Service.Compiler_State.Overflowed;
      Result.Fingerprint := Mix
        (Service.Compiler_State.Fingerprint, Text_Fingerprint (Path));

      for Diagnostic of Service.Compiler_Diagnostics loop
         if Path_Matches_Label (Path, To_String (Diagnostic.File_Label)) then
            Result.Accepted_Count := Result.Accepted_Count + 1;
            Result.Diagnostic_Count := Result.Diagnostic_Count + 1;
            Count_Compiler_Severity (Result, Diagnostic.Severity);
            Result.Fingerprint := Mix
              (Result.Fingerprint, Diagnostic_Fingerprint (Diagnostic));
         end if;
      end loop;

      return Result;
   end Compiler_Status_For_Path;

   function Compiler_Diagnostic_Count
     (Service : Service_State) return Natural is
   begin
      return Natural (Service.Compiler_Diagnostics.Length);
   end Compiler_Diagnostic_Count;

   function Compiler_Diagnostic_At
     (Service : Service_State;
      Index   : Positive) return Compiler_Diagnostic is
   begin
      if Index > Natural (Service.Compiler_Diagnostics.Length) then
         return (others => <>);
      end if;

      return Service.Compiler_Diagnostics.Element (Index);
   end Compiler_Diagnostic_At;

   function Compiler_Diagnostic_Count_For_Path
     (Service : Service_State;
      Path    : String) return Natural is
   begin
      return Compiler_Status_For_Path (Service, Path).Diagnostic_Count;
   end Compiler_Diagnostic_Count_For_Path;

   function Compiler_Diagnostic_At_For_Path
     (Service : Service_State;
      Path    : String;
      Index   : Positive) return Compiler_Diagnostic
   is
      Seen : Natural := 0;
   begin
      for Diagnostic of Service.Compiler_Diagnostics loop
         if Path_Matches_Label (Path, To_String (Diagnostic.File_Label)) then
            Seen := Seen + 1;
            if Seen = Index then
               return Diagnostic;
            end if;
         end if;
      end loop;

      return (others => <>);
   end Compiler_Diagnostic_At_For_Path;

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

   function Complete
     (Service : Service_State;
      Prefix  : String;
      Limit   : Positive := 50) return Completion_Result
   is
      Result : Completion_Result;
      Ordered_Items : Completion_Item_Vectors.Vector;

      function Less (Left, Right : Completion_Item) return Boolean
      is
         Left_Label  : constant String :=
           Editor.Ada_Language_Model.Normalize_Name (To_String (Left.Label));
         Right_Label : constant String :=
           Editor.Ada_Language_Model.Normalize_Name (To_String (Right.Label));
         Left_Path   : constant String := To_String (Left.Target.Path);
         Right_Path  : constant String := To_String (Right.Target.Path);
      begin
         if Left_Label /= Right_Label then
            return Left_Label < Right_Label;
         elsif Left_Path /= Right_Path then
            return Left_Path < Right_Path;
         elsif Left.Target.Line /= Right.Target.Line then
            return Left.Target.Line < Right.Target.Line;
         else
            return Left.Target.Column < Right.Target.Column;
         end if;
      end Less;

      function Same_Label (Left, Right : Completion_Item) return Boolean is
      begin
         return Editor.Ada_Language_Model.Normalize_Name (To_String (Left.Label)) =
           Editor.Ada_Language_Model.Normalize_Name (To_String (Right.Label));
      end Same_Label;

      procedure Insert_Ordered (Item : Completion_Item) is
      begin
         if not Ordered_Items.Is_Empty then
            for I in Ordered_Items.First_Index .. Ordered_Items.Last_Index loop
               if Same_Label (Ordered_Items (I), Item) then
                  if Less (Item, Ordered_Items (I)) then
                     Ordered_Items.Delete (I);
                     exit;
                  else
                     return;
                  end if;
               end if;
            end loop;
         end if;

         if Ordered_Items.Is_Empty then
            Ordered_Items.Append (Item);
            return;
         end if;

         for I in Ordered_Items.First_Index .. Ordered_Items.Last_Index loop
            if Less (Item, Ordered_Items (I)) then
               Ordered_Items.Insert (I, Item);
               if Natural (Ordered_Items.Length) > Limit then
                  Ordered_Items.Delete_Last;
               end if;
               return;
            end if;
         end loop;

         if Natural (Ordered_Items.Length) < Limit then
            Ordered_Items.Append (Item);
         end if;
      end Insert_Ordered;
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
                  Label  : constant String := To_String (Symbol.Name);
               begin
                  if Label'Length > 0
                    and then Starts_With (Label, Prefix)
                  then
                     Insert_Ordered
                       (Completion_Item'
                          (Label  => Symbol.Name,
                           Detail => To_Unbounded_String
                             (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
                                ((Path   => Key.Path,
                                  Key    => Key,
                                  Symbol => Symbol))),
                           Kind   => Symbol.Kind,
                           Target =>
                             (Path   => Key.Path,
                              Line   => Symbol.Source_Span.Start_Line,
                              Column => Symbol.Source_Span.Start_Column),
                           Key    => Key));
                  end if;
               end;
            end loop;
         end;
      end loop;

      for Item of Ordered_Items loop
         Result.Items.Append (Item);
         Result.Status := Service_Success;
         exit when Natural (Result.Items.Length) >= Limit;
      end loop;

      return Result;
   end Complete;

   function Request_Complete
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Prefix  : String;
      Limit   : Positive := 50) return Completion_Result
   is
      Result : Completion_Result;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Completion,
         Semantic_Request_Query_Key
           (Semantic_Request_Completion, Prefix,
            Detail => Positive'Image (Limit)))
      then
         return Completion_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Complete (Service, Prefix, Limit);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Complete;

   function Complete_Current
     (Service              : Service_State;
      Prefix               : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Limit                : Positive := 50) return Completion_Result
   is
      Result        : Completion_Result;
      Ordered_Items : Completion_Item_Vectors.Vector;
      Saw_Stale     : Boolean := False;
      Saw_Current    : Boolean := False;

      function Key_Is_Current
        (Key : Editor.Ada_Project_Index.Indexed_File_Key) return Boolean is
      begin
         return Same_Current_Key
           (Key, Path, Buffer_Token, Buffer_Revision,
            Lifecycle_Generation, Analysis_Fingerprint);
      end Key_Is_Current;

      function Key_Is_Stale_Same_Buffer
        (Key : Editor.Ada_Project_Index.Indexed_File_Key) return Boolean is
      begin
         return Same_Path (To_String (Key.Path), Path)
           and then Key.Buffer_Token = Buffer_Token
           and then not Key_Is_Current (Key);
      end Key_Is_Stale_Same_Buffer;

      function Less (Left, Right : Completion_Item) return Boolean
      is
         Left_Label  : constant String :=
           Editor.Ada_Language_Model.Normalize_Name (To_String (Left.Label));
         Right_Label : constant String :=
           Editor.Ada_Language_Model.Normalize_Name (To_String (Right.Label));
         Left_Path   : constant String := To_String (Left.Target.Path);
         Right_Path  : constant String := To_String (Right.Target.Path);
      begin
         if Left_Label /= Right_Label then
            return Left_Label < Right_Label;
         elsif Left_Path /= Right_Path then
            return Left_Path < Right_Path;
         elsif Left.Target.Line /= Right.Target.Line then
            return Left.Target.Line < Right.Target.Line;
         else
            return Left.Target.Column < Right.Target.Column;
         end if;
      end Less;

      function Same_Label (Left, Right : Completion_Item) return Boolean is
      begin
         return Editor.Ada_Language_Model.Normalize_Name (To_String (Left.Label)) =
           Editor.Ada_Language_Model.Normalize_Name (To_String (Right.Label));
      end Same_Label;

      procedure Insert_Ordered (Item : Completion_Item) is
      begin
         if not Ordered_Items.Is_Empty then
            for I in Ordered_Items.First_Index .. Ordered_Items.Last_Index loop
               if Same_Label (Ordered_Items (I), Item) then
                  if Less (Item, Ordered_Items (I)) then
                     Ordered_Items.Delete (I);
                     exit;
                  else
                     return;
                  end if;
               end if;
            end loop;
         end if;

         if Ordered_Items.Is_Empty then
            Ordered_Items.Append (Item);
            return;
         end if;

         for I in Ordered_Items.First_Index .. Ordered_Items.Last_Index loop
            if Less (Item, Ordered_Items (I)) then
               Ordered_Items.Insert (I, Item);
               if Natural (Ordered_Items.Length) > Limit then
                  Ordered_Items.Delete_Last;
               end if;
               return;
            end if;
         end loop;

         if Natural (Ordered_Items.Length) < Limit then
            Ordered_Items.Append (Item);
         end if;
      end Insert_Ordered;
   begin
      if Editor.Ada_Project_Index.Overflowed (Service.Index) then
         Result.Status := Service_Overflow;
         return Result;
      end if;

      Result.Status := Service_Unavailable;

      for F in 1 .. Editor.Ada_Project_Index.File_Count (Service.Index) loop
         declare
            Key : constant Editor.Ada_Project_Index.Indexed_File_Key :=
              Editor.Ada_Project_Index.File_Key_At (Service.Index, F);
         begin
            if Key_Is_Current (Key) then
               Saw_Current := True;
               declare
                  Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
                    Editor.Ada_Project_Index.File_Analysis_At (Service.Index, F);
               begin
                  if Editor.Ada_Language_Model.Overflowed (Analysis) then
                     Result.Status := Service_Overflow;
                     return Result;
                  end if;

                  for S in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
                     declare
                        Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
                          Editor.Ada_Language_Model.Symbol_At (Analysis, S);
                        Label  : constant String := To_String (Symbol.Name);
                     begin
                        if Label'Length > 0
                          and then Starts_With (Label, Prefix)
                        then
                           Insert_Ordered
                             (Completion_Item'
                                (Label  => Symbol.Name,
                                 Detail => To_Unbounded_String
                                   (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
                                      ((Path   => Key.Path,
                                        Key    => Key,
                                        Symbol => Symbol))),
                                 Kind   => Symbol.Kind,
                                 Target =>
                                   (Path   => Key.Path,
                                    Line   => Symbol.Source_Span.Start_Line,
                                    Column => Symbol.Source_Span.Start_Column),
                                 Key    => Key));
                        end if;
                     end;
                  end loop;
               end;
            elsif Key_Is_Stale_Same_Buffer (Key) then
               Saw_Stale := True;
            else
               declare
                  Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
                    Editor.Ada_Project_Index.File_Analysis_At (Service.Index, F);
               begin
                  if Editor.Ada_Language_Model.Overflowed (Analysis) then
                     Result.Status := Service_Overflow;
                     return Result;
                  end if;

                  for S in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
                     declare
                        Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
                          Editor.Ada_Language_Model.Symbol_At (Analysis, S);
                        Label  : constant String := To_String (Symbol.Name);
                     begin
                        if Label'Length > 0
                          and then Starts_With (Label, Prefix)
                        then
                           Insert_Ordered
                             (Completion_Item'
                                (Label  => Symbol.Name,
                                 Detail => To_Unbounded_String
                                   (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
                                      ((Path   => Key.Path,
                                        Key    => Key,
                                        Symbol => Symbol))),
                                 Kind   => Symbol.Kind,
                                 Target =>
                                   (Path   => Key.Path,
                                    Line   => Symbol.Source_Span.Start_Line,
                                    Column => Symbol.Source_Span.Start_Column),
                                 Key    => Key));
                        end if;
                     end;
                  end loop;
               end;
            end if;
         end;
      end loop;

      if not Saw_Current and then Saw_Stale then
         Result.Status := Service_Stale;
      elsif Saw_Current then
         for Item of Ordered_Items loop
            Result.Items.Append (Item);
            Result.Status := Service_Success;
            exit when Natural (Result.Items.Length) >= Limit;
         end loop;
      end if;

      return Result;
   end Complete_Current;

   function Request_Complete_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Prefix               : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Limit                : Positive := 50) return Completion_Result
   is
      Result : Completion_Result;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Completion,
         Semantic_Current_Request_Query_Key
           (Semantic_Request_Completion, Prefix, Path, Buffer_Token,
            Buffer_Revision, Lifecycle_Generation, Analysis_Fingerprint,
            Detail => Positive'Image (Limit)))
      then
         return Completion_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Complete_Current
        (Service, Prefix, Path, Buffer_Token, Buffer_Revision,
         Lifecycle_Generation, Analysis_Fingerprint, Limit);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Complete_Current;

   function Hover
     (Service : Service_State;
      Name    : String) return Hover_Result
   is
      Target : constant Language_Target :=
        Goto_Declaration
          (Service, Name, Editor.Ada_Language_Model.Symbol_Unknown);
      Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve
          (Service.Index, Name, Max_Matches => 2);
      Result : Hover_Result;
   begin
      if Target.Status = Service_Success then
         Result.Status := Service_Success;
         Result.Label := Target.Name;
         Result.Detail := Target.Detail;
         Result.Target := Target.Target;
         Result.Key := Target.Key;
         return Result;
      end if;

      if Matches.Overflow then
         Result.Status := Service_Overflow;
      elsif Matches.Matches.Is_Empty then
         Result.Status := Service_Unavailable;
      else
         declare
            First : constant Editor.Ada_Project_Index.Indexed_Symbol :=
              Matches.Matches (Matches.Matches.First_Index);
         begin
            Result.Status :=
              (if Natural (Matches.Matches.Length) = 1 then Service_Success
               else Service_Ambiguous);
            Result.Label := First.Symbol.Name;
            Result.Detail := To_Unbounded_String
              (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
                 (First));
            Result.Target :=
              (Path   => First.Path,
               Line   => First.Symbol.Source_Span.Start_Line,
               Column => First.Symbol.Source_Span.Start_Column);
            Result.Key := First.Key;
         end;
      end if;

      return Result;
   end Hover;

   function Request_Hover
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String) return Hover_Result
   is
      Result : Hover_Result;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Hover, Name)
      then
         return Hover_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Hover (Service, Name);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Hover;

   function Hover_Current
     (Service              : Service_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Hover_Result
   is
      Current_Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve_Current
          (Service.Index, Name, Path, Buffer_Token, Buffer_Revision,
           Lifecycle_Generation, Analysis_Fingerprint);
      Current_Snapshot_Available : constant Boolean :=
        Editor.Ada_Project_Index.Contains_Current
          (Service.Index, Path, Buffer_Token, Buffer_Revision,
           Lifecycle_Generation, Analysis_Fingerprint);
      Result : Hover_Result;
   begin
      if Current_Matches.Overflow then
         Result.Status := Service_Overflow;
         return Result;
      elsif not Current_Matches.Matches.Is_Empty then
         declare
            First : constant Editor.Ada_Project_Index.Indexed_Symbol :=
              Current_Matches.Matches (Current_Matches.Matches.First_Index);
         begin
            Result.Status :=
              (if Natural (Current_Matches.Matches.Length) = 1
               then Service_Success
               else Service_Ambiguous);
            Result.Label := First.Symbol.Name;
            Result.Detail := To_Unbounded_String
              (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
                 (First));
            Result.Target :=
              (Path   => First.Path,
               Line   => First.Symbol.Source_Span.Start_Line,
               Column => First.Symbol.Source_Span.Start_Column);
            Result.Key := First.Key;
         end;
         return Result;
      elsif Current_Snapshot_Available then
         Result.Status := Service_Unavailable;
         return Result;
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
   end Hover_Current;

   function Request_Hover_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Hover_Result
   is
      Result : Hover_Result;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Hover,
         Semantic_Current_Request_Query_Key
           (Semantic_Request_Hover, Name, Path, Buffer_Token,
            Buffer_Revision, Lifecycle_Generation, Analysis_Fingerprint))
      then
         return Hover_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Hover_Current
        (Service, Name, Path, Buffer_Token, Buffer_Revision,
         Lifecycle_Generation, Analysis_Fingerprint);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Hover_Current;

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

end Editor.Ada_Language_Service;
