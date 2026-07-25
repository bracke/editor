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

package body Editor.Ada_Language_Service.Diagnostics is

   use type Editor.External_Producers.Diagnostics_Types.Compiler_Diagnostic_Severity;

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
         Editor.External_Producers.Diagnostics_Types.Compiler_Diagnostic_Severity'Pos
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
         when Editor.External_Producers.Diagnostics_Types.Compiler_Error
            | Editor.External_Producers.Diagnostics_Types.Compiler_Fatal =>
            Status.Error_Count := Status.Error_Count + 1;
         when Editor.External_Producers.Diagnostics_Types.Compiler_Warning =>
            Status.Warning_Count := Status.Warning_Count + 1;
         when Editor.External_Producers.Diagnostics_Types.Compiler_Info =>
            Status.Info_Count := Status.Info_Count + 1;
         when Editor.External_Producers.Diagnostics_Types.Compiler_Note =>
            Status.Note_Count := Status.Note_Count + 1;
         when Editor.External_Producers.Diagnostics_Types.Compiler_Unknown =>
            Status.Unknown_Count := Status.Unknown_Count + 1;
      end case;
   end Count_Compiler_Severity;

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
      Lines           : Editor.External_Producers.Diagnostic_Text_Lines.Array_Type;
      Tool_Name       : String := "gnat";
      Run_Fingerprint : Natural := 0)
   is
      Parsing_Lines : Editor.External_Producers.Diagnostic_Line_Parsing.Text_Line_Array;
      Parsed : Editor.External_Producers.Diagnostic_Line_Parsing.Batch_Parse_Result;
      State : Compiler_Backend_Status;
   begin
      if not Lines.Is_Empty then
         for I in Lines.First_Index .. Lines.Last_Index loop
            Parsing_Lines.Append (Lines.Element (I));
         end loop;
      end if;

      Parsed :=
        Editor.External_Producers.Diagnostic_Line_Parsing.Parse_Compiler_Diagnostic_Lines
          (Parsing_Lines, Tool_Name);
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
              (Severity     =>
                 Compiler_Diagnostic_Severity'Val
                   (Editor.External_Producers.Diagnostics_Types.Compiler_Severity'Pos
                      (R.Severity)),
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

end Editor.Ada_Language_Service.Diagnostics;
