with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Line_Dispatch;
with Editor.Ada_Declaration_Parser.Line_Metadata;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Declaration_Parser.Representation_Metadata;
with Editor.Ada_Declaration_Parser.Representation_Static_Values;
with Editor.Ada_Declaration_Parser.Same_Line_Declarations;
with Editor.Ada_Declaration_Parser.Same_Line_Emitters;
with Editor.Ada_Declaration_Parser.Static_Attribute_Registry;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker is

   pragma Suppress (Overflow_Check);

   use Editor.Ada_Language_Model;
   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;

   function Has_Access_Subprogram_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.Has_Access_Subprogram_Metadata;




   function Has_Access_Protected_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.Has_Access_Protected_Metadata;

   function Has_Aliased_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.Has_Aliased_Metadata;

   function Has_Default_Expression_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Default_Expression_Metadata;

   function Has_Entry_Family_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.Has_Entry_Family_Metadata;

   function Has_Profile_Mode_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Profile_Mode_Metadata;

   function Has_Entry_Barrier_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Entry_Barrier_Metadata;

   function Has_Class_Wide_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.Has_Class_Wide_Metadata;

   function Has_Named_Number_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Named_Number_Metadata;

   function Has_Deferred_Constant_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Deferred_Constant_Metadata;

   function Has_Null_Subprogram_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Null_Subprogram_Metadata;

   function Has_Expression_Function_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Expression_Function_Metadata;

   function Has_Null_Record_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Null_Record_Metadata;

   function Has_Discriminant_Part_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Discriminant_Part_Metadata;

   function Has_Body_Stub_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Body_Stub_Metadata;

   function Has_Constraint_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Constraint_Metadata;

   function Has_Child_Unit_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Child_Unit_Metadata;

   function Has_Generic_Actual_Part_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Metadata.Has_Generic_Actual_Part_Metadata;

   function Has_Incomplete_Type_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.Has_Incomplete_Type_Metadata;


   function Generic_Formal_Type_Family_From_Line
     (Line : String) return Generic_Formal_Type_Family
   is
   begin
      return Metadata_Helpers.Generic_Formal_Type_Family_From_Line (Line);
   end Generic_Formal_Type_Family_From_Line;


   function Is_Scope_End (Lower_Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.Is_Scope_End;

   function First_Non_Blank_Column (Line : String) return Positive
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.First_Non_Blank_Column;

   function Matching_Pragma_Close_Pos (Line : String; Open_Pos : Natural) return Natural
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Matching_Pragma_Close_Pos;

   function Is_Pragma_Character_Literal_At
     (Text : String; Pos : Natural; Last : Natural) return Boolean
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Is_Pragma_Character_Literal_At;

   function Pragma_Code_Preserving_Literals (Line : String) return String
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Code_Preserving_Literals;

   function Pragma_Target (Line : String) return String
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Target;

   function Pragma_Name_Of (Line : String) return String
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Name_Of;

   function Pragma_Argument_Count (Line : String) return Natural
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Argument_Count;

   function Pragma_Argument (Line : String; Index : Positive) return String
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Argument;

   function Top_Level_Pragma_Association_Arrow (Arg : String) return Natural
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Top_Level_Pragma_Association_Arrow;

   function Pragma_Argument_Name (Arg : String) return String
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Argument_Name;

   function Pragma_Argument_Value (Arg : String) return String
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Argument_Value;

   function Named_Pragma_Argument (Line, Name : String) return String
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Named_Pragma_Argument;

   function Interfacing_Pragma_Value
     (Line               : String;
      Name               : String;
      Positional_Fallback : Positive) return String
     renames Editor.Ada_Declaration_Parser.Pragma_Helpers.Interfacing_Pragma_Value;

   function Read_Name
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean := True) return String
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Read_Name;

   function Read_Function_Name
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean := True) return String
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Read_Function_Name;

   function Declaration_Name_Position
     (Text          : String;
      Declared_Name : String) return Natural
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Declaration_Name_Position;

   function Read_Subtype_Mark
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean := True) return String
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Read_Subtype_Mark;

   function Profile_From
     (Line          : String;
      Declared_Name : String) return String
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Profile_From;

   function Profile_Continuation_From_Line (Line : String) return String
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Profile_Continuation_From_Line;

   function Strip_Prefixes (Line : String) return String
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Strip_Prefixes;

   function Target_After (Line, Marker : String) return String
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Target_After;

   function Declaration_Target_From_Line_Start (Line : String) return String is
      Start : Natural := Line'First;
   begin
      while Start <= Line'Last
        and then (Line (Start) = ' ' or else Line (Start) = Ada.Characters.Latin_1.HT)
      loop
         Start := Start + 1;
      end loop;

      if Start > Line'Last then
         return "";
      end if;

      declare
         Target       : constant String := Read_Function_Name (Line, Positive (Start), True);
         Target_Lower : constant String := Lower (Target);
      begin
         if Target'Length = 0
           or else Target_Lower = "is"
           or else Target_Lower = "new"
           or else Target_Lower = "renames"
           or else Target_Lower = "with"
           or else Target_Lower = "private"
           or else Target_Lower = "package"
           or else Target_Lower = "procedure"
           or else Target_Lower = "function"
           or else Target_Lower = "return"
           or else Target_Lower = "separate"
         then
            return "";
         end if;

         return Target;
      end;
   end Declaration_Target_From_Line_Start;


   function Generic_Formal_Package_Target_From_Line_Start
     (Line : String) return String
   is
      Start : Natural := Line'First;

   begin
      Lexical_Helpers.Skip_Blanks (Line, Start);
      if Start > Line'Last then
         return "";
      end if;

      if Lexical_Helpers.Starts_At_Word (Line, Start, "is") then
         Start := Start + 2;
         Lexical_Helpers.Skip_Blanks (Line, Start);
      end if;

      if Lexical_Helpers.Starts_At_Word (Line, Start, "new") then
         Start := Start + 3;
         Lexical_Helpers.Skip_Blanks (Line, Start);
      else
         return "";
      end if;

      if Start > Line'Last then
         return "";
      end if;

      declare
         Target       : constant String := Read_Function_Name (Line, Positive (Start), True);
         Target_Lower : constant String := Lower (Target);
      begin
         if Target'Length = 0
           or else Target_Lower = "is"
           or else Target_Lower = "new"
           or else Target_Lower = "with"
           or else Target_Lower = "package"
           or else Target_Lower = "renames"
           or else Target_Lower = "private"
         then
            return "";
         end if;

         return Target;
      end;
   end Generic_Formal_Package_Target_From_Line_Start;






   function Generic_Formal_Subprogram_Default_After_Is
     (Line : String) return String
   is
      L : constant String := Lower (Line);
      P : constant Natural := Ada.Strings.Fixed.Index (L, " is ");
      Start : Natural;

   begin
      if P = 0 then
         return "";
      end if;

      Start := P + 4;
      Lexical_Helpers.Skip_Blanks (Line, Start);

      if Start > Line'Last then
         return "";
      end if;

      if Start + 1 <= Line'Last
        and then Line (Start) = '<'
        and then Line (Start + 1) = '>'
      then
         return "<>";
      elsif Lexical_Helpers.Starts_At_Word (Line, Start, "null") then
         return "null";
      else
         return Read_Function_Name (Line, Positive (Start), True);
      end if;
   end Generic_Formal_Subprogram_Default_After_Is;


   function Generic_Formal_Subprogram_Target_From_Line_Start
     (Line : String) return String
   is
      Start : Natural := Line'First;

   begin
      Lexical_Helpers.Skip_Blanks (Line, Start);
      if Start > Line'Last then
         return "";
      end if;

      if Lexical_Helpers.Starts_At_Word (Line, Start, "is") then
         Start := Start + 2;
         Lexical_Helpers.Skip_Blanks (Line, Start);
      end if;

      if Start > Line'Last then
         return "";
      end if;

      if Start + 1 <= Line'Last
        and then Line (Start) = '<'
        and then Line (Start + 1) = '>'
      then
         return "<>";
      elsif Lexical_Helpers.Starts_At_Word (Line, Start, "null") then
         return "null";
      end if;

      declare
         Target       : constant String := Read_Function_Name (Line, Positive (Start), True);
         Target_Lower : constant String := Lower (Target);
      begin
         if Target'Length = 0
           or else Target_Lower = "is"
           or else Target_Lower = "with"
           or else Target_Lower = "package"
           or else Target_Lower = "procedure"
           or else Target_Lower = "function"
           or else Target_Lower = "return"
           or else Target_Lower = "private"
         then
            return "";
         end if;

         return Target;
      end;
   end Generic_Formal_Subprogram_Target_From_Line_Start;


   function Subtype_Target_After_Is (Line : String) return String is
   begin
      return Target_Helpers.Subtype_Target_After_Is (Line);
   end Subtype_Target_After_Is;

   function Subtype_Target_From_Line_Start (Line : String) return String is
      Start : Natural := Line'First;
   begin
      while Start <= Line'Last
        and then (Line (Start) = ' ' or else Line (Start) = Ada.Characters.Latin_1.HT)
      loop
         Start := Start + 1;
      end loop;

      if Start > Line'Last then
         return "";
      end if;

      if Start + 7 <= Line'Last
        and then Lower (Line (Start .. Start + 7)) = "not null"
      then
         Start := Start + 8;
         while Start <= Line'Last
           and then (Line (Start) = ' ' or else Line (Start) = Ada.Characters.Latin_1.HT)
         loop
            Start := Start + 1;
         end loop;
      end if;

      declare
         Target       : constant String := Read_Subtype_Mark (Line, Positive (Start), True);
         Target_Lower : constant String := Lower (Target);
      begin
         if Target'Length = 0
           or else Target_Lower = "range"
           or else Target_Lower = "with"
           or else Target_Lower = "renames"
           or else Target_Lower = "is"
           or else Target_Lower = "record"
           or else Target_Lower = "array"
           or else Target_Lower = "access"
         then
            return "";
         end if;

         return Target;
      end;
   end Subtype_Target_From_Line_Start;

   function Derived_Target_From_Line_Start (Line : String) return String is
      Start : Natural := Line'First;
   begin
      while Start <= Line'Last
        and then (Line (Start) = ' ' or else Line (Start) = Ada.Characters.Latin_1.HT)
      loop
         Start := Start + 1;
      end loop;

      if Start > Line'Last then
         return "";
      end if;

      declare
         Target       : constant String := Read_Subtype_Mark (Line, Positive (Start), True);
         Target_Lower : constant String := Lower (Target);
      begin
         if Target'Length = 0
           or else Target_Lower = "with"
           or else Target_Lower = "record"
           or else Target_Lower = "private"
           or else Target_Lower = "interface"
           or else Target_Lower = "is"
           or else Target_Lower = "new"
           or else Target_Lower = "abstract"
           or else Target_Lower = "tagged"
           or else Target_Lower = "limited"
         then
            return "";
         end if;

         return Target;
      end;
   end Derived_Target_From_Line_Start;

   function Skip_Component_Qualifiers
     (Line  : String;
      Start : Natural) return Natural
   is
   begin
      return Target_Helpers.Skip_Component_Qualifiers (Line, Start);
   end Skip_Component_Qualifiers;

   function Array_Element_Target (Line : String) return String is
   begin
      return Target_Helpers.Array_Element_Target (Line);
   end Array_Element_Target;


   function Access_Subprogram_Profile (Line : String) return String is
   begin
      return Target_Helpers.Access_Subprogram_Profile (Line);
   end Access_Subprogram_Profile;

   function Access_Object_Target (Line : String) return String is
   begin
      return Target_Helpers.Access_Object_Target (Line);
   end Access_Object_Target;

   function Access_Target_From_Line_Start (Line : String) return String is
      Start : Natural := Skip_Component_Qualifiers (Line, Line'First);
   begin
      if Start > Line'Last then
         return "";
      end if;

      declare
         Target : constant String := Read_Subtype_Mark (Line, Positive (Start), True);
         Target_Lower : constant String := Lower (Target);
      begin
         if Target'Length = 0
           or else Target_Lower = "procedure"
           or else Target_Lower = "function"
           or else Target_Lower = "protected"
           or else Target_Lower = "with"
           or else Target_Lower = "renames"
           or else Target_Lower = "is"
         then
            return "";
         end if;
         return Target;
      end;
   end Access_Target_From_Line_Start;


   function Array_Target_From_Line (Line : String) return String is
   begin
      --  Continuation for split array type declarations:
      --     type Table is array
      --        (Positive range <>) of Element;
      --  Reuse the bounded element-target reader on the continuation line;
      --  it ignores index constraints and returns only the component subtype
      --  mark after the top-level "of".
      return Array_Element_Target (Line);
   end Array_Target_From_Line;

   function Return_Target_From_Position
     (Line  : String;
      Start : Natural) return String
   is
   begin
      return Target_Helpers.Return_Target_From_Position (Line, Start);
   end Return_Target_From_Position;

   function Return_Target_From_Line_Start (Line : String) return String is
   begin
      return Target_Helpers.Return_Target_From_Line_Start (Line);
   end Return_Target_From_Line_Start;

   function Function_Return_Target (Line : String) return String is
   begin
      return Target_Helpers.Function_Return_Target (Line);
   end Function_Return_Target;

   function Interface_Parent_Target (Line : String) return String is
   begin
      return Target_Helpers.Interface_Parent_Target (Line);
   end Interface_Parent_Target;

   function Interface_Target_From_Line_Start (Line : String) return String is
   begin
      return Target_Helpers.Interface_Target_From_Line_Start (Line);
   end Interface_Target_From_Line_Start;

   function Object_Target_After_Colon (Line : String) return String is
   begin
      return Target_Helpers.Object_Target_After_Colon (Line);
   end Object_Target_After_Colon;

   function Object_Target_From_Line_Start (Line : String) return String is
      Start : Natural := Skip_Component_Qualifiers (Line, Line'First);
   begin
      if Start > Line'Last then
         return "";
      end if;

      declare
         Candidate       : constant String := Read_Subtype_Mark (Line, Positive (Start), True);
         Candidate_Lower : constant String := Lower (Candidate);
      begin
         if Candidate'Length = 0
           or else Candidate_Lower = "array"
           or else Candidate_Lower = "access"
           or else Candidate_Lower = "record"
           or else Candidate_Lower = "range"
           or else Candidate_Lower = "procedure"
           or else Candidate_Lower = "function"
           or else Candidate_Lower = "exception"
           or else Candidate_Lower = "renames"
           or else Candidate_Lower = "with"
           or else Candidate_Lower = "is"
           or else Candidate_Lower = "return"
         then
            return "";
         end if;

         return Candidate;
      end;
   end Object_Target_From_Line_Start;

   function Separate_Parent_Name (Line : String) return String is
      Code  : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      Open  : Natural := 0;
      Close : Natural := 0;
   begin
      for I in Code'Range loop
         if Code (I) = '(' then
            Open := I;
            exit;
         end if;
      end loop;
      if Open = 0 then
         return "";
      end if;
      for I in Open + 1 .. Code'Last loop
         if Code (I) = ')' then
            Close := I;
            exit;
         end if;
      end loop;
      if Close = 0 or else Close <= Open + 1 then
         return "";
      end if;
      return Trim (Line (Open + 1 .. Close - 1));
   end Separate_Parent_Name;

   Max_Collected_Object_Names : constant Natural :=
     Declaration_Collectors.Max_Collected_Object_Names;

   procedure Add_Object_Names_Collecting
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Kind            : Symbol_Kind;
      Collected       : in out Collected_Symbol_List;
      Collected_Count : in out Natural;
      Column_Base     : Natural := 0;
      Flags           : Declaration_Flags := (others => False))
   is
      Type_Target : constant String :=
        (if Kind = Symbol_Exception then "" else Object_Target_After_Colon (Raw_Line));
   begin
      Declaration_Collectors.Add_Object_Names_Collecting
        (Analysis        => Analysis,
         Raw_Line        => Raw_Line,
         Line_Number     => Line_Number,
         Depth           => Depth,
         Parent          => Parent,
         Kind            => Kind,
         Type_Target     => Type_Target,
         Collected       => Collected,
         Collected_Count => Collected_Count,
         Column_Base     => Column_Base,
         Flags           => Flags);
   end Add_Object_Names_Collecting;


   procedure Add_Object_Names
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Column_Base : Natural := 0;
      Flags       : Declaration_Flags := (others => False))
   is
      Type_Target : constant String :=
        (if Kind = Symbol_Exception then "" else Object_Target_After_Colon (Raw_Line));
   begin
      Declaration_Collectors.Add_Object_Names
        (Analysis    => Analysis,
         Raw_Line    => Raw_Line,
         Line_Number => Line_Number,
         Depth       => Depth,
         Parent      => Parent,
         Kind        => Kind,
         Type_Target => Type_Target,
         Column_Base => Column_Base,
         Flags       => Flags);
   end Add_Object_Names;

   procedure Add_Object_Name_Groups
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Column_Base : Natural := 0;
      Flags       : Declaration_Flags := (others => False))
   is
   begin
      Declaration_Collectors.Add_Object_Name_Groups
        (Analysis    => Analysis,
         Raw_Line    => Raw_Line,
         Line_Number => Line_Number,
         Depth       => Depth,
         Parent      => Parent,
         Kind        => Kind,
         Column_Base => Column_Base,
         Flags       => Flags);
   end Add_Object_Name_Groups;






   procedure Add_Object_Rename_Declaration_Groups
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id)
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;
      Nesting       : Natural := 0;

      procedure Add_Rename_Segment
        (First : Natural;
         Last  : Natural)
      is
         Segment_Lower : constant String := Lower (Code (First .. Last));
         Segment_Kind  : Symbol_Kind := Symbol_Object;
         Owners        : Collected_Symbol_List := (others => No_Symbol);
         Count         : Natural := 0;
         Rename_Target : constant String := Target_After (Raw_Line (First .. Last), "renames");
      begin
         if First > Last then
            return;
         end if;

         if Ada.Strings.Fixed.Index (Segment_Lower, ": exception") /= 0 then
            Segment_Kind := Symbol_Exception;
         elsif Has_Object_Constant_Qualifier (Raw_Line (First .. Last)) then
            Segment_Kind := Symbol_Constant;
         end if;

         Add_Object_Names_Collecting
           (Analysis, Raw_Line (First .. Last), Line_Number,
            Depth, Parent, Segment_Kind,
            Column_Base => First - Raw_Line'First,
            Flags => (Is_Rename => True, others => False),
            Collected => Owners, Collected_Count => Count);

         for I in 1 .. Count loop
            Set_Symbol_Target (Analysis, Owners (I), Rename_Target);
         end loop;
      end Add_Rename_Segment;
   begin
      --  Object/exception renamings can appear as multiple declarations on
      --  one physical source line.  Treat each semicolon-separated rename as
      --  its own declaration so later renamed symbols keep Is_Rename and get
      --  their own renamed target rather than being hidden behind the first
      --  segment.
      for I in Code'Range loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';' and then Nesting = 0 then
            if I > Segment_Start then
               Add_Rename_Segment (Segment_Start, I - 1);
            end if;
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= Raw_Line'Last then
         Add_Rename_Segment (Segment_Start, Raw_Line'Last);
      end if;
   end Add_Object_Rename_Declaration_Groups;


   procedure Add_Object_Declaration_Groups
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Flags       : Declaration_Flags := (others => False))
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;
      Nesting       : Natural := 0;

      procedure Add_Declaration_Segment
        (First : Natural;
         Last  : Natural)
      is
         Segment_Lower : constant String := Lower (Code (First .. Last));
         Segment_Kind  : Symbol_Kind := Kind;
      begin
         if First > Last then
            return;
         end if;

         if Kind /= Symbol_Generic_Formal_Object then
            if Ada.Strings.Fixed.Index (Segment_Lower, ": exception") /= 0 then
               Segment_Kind := Symbol_Exception;
            elsif Has_Object_Constant_Qualifier (Raw_Line (First .. Last)) then
               Segment_Kind := Symbol_Constant;
            else
               Segment_Kind := Symbol_Object;
            end if;
         end if;

         declare
            Owners  : Collected_Symbol_List := (others => No_Symbol);
            Count   : Natural := 0;
            Segment : constant String := Raw_Line (First .. Last);
            Profile : constant String := Access_Subprogram_Profile (Segment);
         begin
            Add_Object_Names_Collecting
              (Analysis, Segment, Line_Number,
               Depth, Parent, Segment_Kind,
               Column_Base => First - Raw_Line'First,
               Flags => Flags,
               Collected => Owners, Collected_Count => Count);

            if Profile'Length /= 0 then
               for I in 1 .. Count loop
                  Set_Symbol_Profile (Analysis, Owners (I), Profile);
               end loop;
            end if;
         end;
      end Add_Declaration_Segment;
   begin
      --  Multiple ordinary object/constant/exception declarations may share
      --  one physical source line:
      --     A : Natural; B, C : constant Boolean;
      --  Keep the same colon-gated object-name recognizer, but apply it per
      --  declaration segment so later declarations are not hidden behind the
      --  first semicolon.  Split only at top-level semicolons: semicolons
      --  inside anonymous access-to-subprogram profiles are metadata, not
      --  declaration separators.  keeps generic-formal object
      --  profile semicolons inside Add_Object_Declaration_Groups itself.
      --  Source columns and per-segment value kind
      --  are preserved by carrying the segment offset and recomputing
      --  constants / exceptions for each declaration group.
      for I in Code'Range loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';' and then Nesting = 0 then
            if I > Segment_Start then
               Add_Declaration_Segment (Segment_Start, I - 1);
            end if;
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= Raw_Line'Last then
         Add_Declaration_Segment (Segment_Start, Raw_Line'Last);
      end if;
   end Add_Object_Declaration_Groups;


   procedure Add_Discriminant_Names
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id)
   is
   begin
      Declaration_Collectors.Add_Discriminant_Names
        (Analysis, Raw_Line, Line_Number, Depth, Parent);
   end Add_Discriminant_Names;



   procedure Add_Record_Component_Names
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id)
   is
   begin
      Declaration_Collectors.Add_Record_Component_Names
        (Analysis      => Analysis,
         Raw_Line      => Raw_Line,
         Line_Number   => Line_Number,
         Depth         => Depth,
         Parent        => Parent,
         Mark_Metadata => Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase.Mark_Declaration_Form_Metadata'Access);
   end Add_Record_Component_Names;

   procedure Add_Enumeration_Literals
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id)
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Open : Natural := 0;
      I    : Natural;
   begin
      for P in Code'Range loop
         if Code (P) = '(' then
            Open := P;
            exit;
         elsif Code (P) = ';' then
            return;
         end if;
      end loop;
      if Open = 0 then
         return;
      end if;
      I := Open + 1;
      while I <= Code'Last loop
         if Code (I) = ')' or else Code (I) = ';' then
            return;
         elsif (Raw_Line (I) >= 'A' and then Raw_Line (I) <= 'Z')
           or else (Raw_Line (I) >= 'a' and then Raw_Line (I) <= 'z')
         then
            declare
               J : Natural := I;
            begin
               while J <= Raw_Line'Last and then Is_Word_Char (Raw_Line (J)) loop
                  J := J + 1;
               end loop;
               declare
                  Ignored : constant Symbol_Id := Add_Symbol
                    (Analysis, Raw_Line (I .. J - 1), Symbol_Enumeration_Literal,
                     (Line_Number, Positive (I - Raw_Line'First + 1), Line_Number,
                      Positive (J - Raw_Line'First)),
                     Positive (I - Raw_Line'First + 1),
                     Enclosing_Scope => Scope_Id (Natural (Parent)),
                     Parent_Symbol => Parent, Depth => Depth);
               begin
                  null;
               end;
               I := J;
            end;
         elsif Raw_Line (I) = Character'Val (16#27#)
           and then Editor.Ada_Syntax_Core.Looks_Like_Simple_Character_Literal (Raw_Line, I)
         then
            declare
               Last : constant Natural := I + Editor.Ada_Syntax_Core.Simple_Character_Literal_Length (Raw_Line, I) - 1;
            begin
               if Last <= Raw_Line'Last then
                  declare
                     Ignored : constant Symbol_Id := Add_Symbol
                       (Analysis, Raw_Line (I .. Last), Symbol_Enumeration_Literal,
                        (Line_Number, Positive (I - Raw_Line'First + 1), Line_Number,
                         Positive (Last - Raw_Line'First + 1)),
                        Positive (I - Raw_Line'First + 1),
                        Enclosing_Scope => Scope_Id (Natural (Parent)),
                        Parent_Symbol => Parent, Depth => Depth);
                  begin
                     null;
                  end;
               end if;
               I := Last + 1;
            end;
         else
            I := I + 1;
         end if;
      end loop;
   end Add_Enumeration_Literals;

   procedure Add_Enumeration_Literals_Continuation
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id)
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      I    : Natural := Code'First;
   begin
      while I <= Code'Last loop
         if Code (I) = ')' or else Code (I) = ';' then
            return;
         elsif (Raw_Line (I) >= 'A' and then Raw_Line (I) <= 'Z')
           or else (Raw_Line (I) >= 'a' and then Raw_Line (I) <= 'z')
         then
            declare
               J : Natural := I;
            begin
               while J <= Raw_Line'Last and then Is_Word_Char (Raw_Line (J)) loop
                  J := J + 1;
               end loop;
               declare
                  Ignored : constant Symbol_Id := Add_Symbol
                    (Analysis, Raw_Line (I .. J - 1), Symbol_Enumeration_Literal,
                     (Line_Number, Positive (I - Raw_Line'First + 1), Line_Number,
                      Positive (J - Raw_Line'First)),
                     Positive (I - Raw_Line'First + 1),
                     Enclosing_Scope => Scope_Id (Natural (Parent)),
                     Parent_Symbol => Parent, Depth => Depth);
               begin
                  null;
               end;
               I := J;
            end;
         elsif Raw_Line (I) = Character'Val (16#27#)
           and then Editor.Ada_Syntax_Core.Looks_Like_Simple_Character_Literal (Raw_Line, I)
         then
            declare
               Last : constant Natural := I + Editor.Ada_Syntax_Core.Simple_Character_Literal_Length (Raw_Line, I) - 1;
            begin
               if Last <= Raw_Line'Last then
                  declare
                     Ignored : constant Symbol_Id := Add_Symbol
                       (Analysis, Raw_Line (I .. Last), Symbol_Enumeration_Literal,
                        (Line_Number, Positive (I - Raw_Line'First + 1), Line_Number,
                         Positive (Last - Raw_Line'First + 1)),
                        Positive (I - Raw_Line'First + 1),
                        Enclosing_Scope => Scope_Id (Natural (Parent)),
                        Parent_Symbol => Parent, Depth => Depth);
                  begin
                     null;
                  end;
               end if;
               I := Last + 1;
            end;
         else
            I := I + 1;
         end if;
      end loop;
   end Add_Enumeration_Literals_Continuation;


   procedure Add_Profile_Parameter_Names
     (Analysis      : in out Analysis_Result;
      Raw_Line      : String;
      Line_Number   : Positive;
      Depth         : Natural;
      Parent        : Symbol_Id;
      Declared_Name : String;
      Pending_Profile_Access_Target_Owners : in out Collected_Symbol_List;
      Pending_Profile_Access_Target_Count  : in out Natural)
   is
   begin
      Profile_Parameter_Collectors.Add_Profile_Parameter_Names
        (Analysis, Raw_Line, Line_Number, Depth, Parent, Declared_Name,
         Pending_Profile_Access_Target_Owners,
         Pending_Profile_Access_Target_Count);
   end Add_Profile_Parameter_Names;


   function Profile_Still_Open
     (Raw_Line      : String;
      Declared_Name : String) return Boolean
   is
   begin
      return Profile_Parameter_Collectors.Profile_Still_Open
        (Raw_Line, Declared_Name);
   end Profile_Still_Open;

   procedure Add_Profile_Parameter_Names_Continuation
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Pending_Profile_Access_Target_Owners : in out Collected_Symbol_List;
      Pending_Profile_Access_Target_Count  : in out Natural;
      Closed      : out Boolean)
   is
   begin
      Profile_Parameter_Collectors.Add_Profile_Parameter_Names_Continuation
        (Analysis, Raw_Line, Line_Number, Depth, Parent,
         Pending_Profile_Access_Target_Owners,
         Pending_Profile_Access_Target_Count, Closed);
   end Add_Profile_Parameter_Names_Continuation;

   procedure Parse_Line
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Context     : in out Parse_Line_Context) is separate;

   procedure Project_Syntax_Tree_Into_Model
     (Analysis    : in out Analysis_Result;
      Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Source_Text : String) is separate;

   procedure Add_Executable_Bindings_From_Text
     (Analysis : in out Analysis_Result;
      Text     : String) is separate;

   procedure Add_Legality_Diagnostics (Analysis : in out Analysis_Result) is separate;

   function Parse
     (Text         : String;
      Buffer_Label : String := "") return Analysis_Result is separate;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;
