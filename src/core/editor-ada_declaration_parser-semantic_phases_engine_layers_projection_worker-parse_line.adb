with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Compact_Record_Tail_Phase;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Generic_Tail_Phase;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Phase_States;
with Editor.Ada_Declaration_Parser.Parse_Line_Pending_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase;
with Editor.Ada_Declaration_Parser.Line_Dispatch;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase;
with Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Declaration_Parser.Representation_Metadata;
with Editor.Ada_Declaration_Parser.Representation_Static_Values;
with Editor.Ada_Declaration_Parser.Static_Attribute_Registry;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers;
with Editor.Ada_Declaration_Parser.Source_Awareness;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker.Statement_Awareness;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Language_Model;
with Editor.Ada_Symbol_Resolver;

use Editor.Ada_Language_Model;
use Editor.Text_Helpers;
use Editor.Ada_Declaration_Parser.Lexical_Helpers;
use Editor.Ada_Declaration_Parser.Source_Awareness;
use Editor.Ada_Declaration_Parser.Metadata_Helpers;
use Editor.Ada_Declaration_Parser.Parse_Line_Phase_States;
separate (Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker)
   procedure Parse_Line
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Context     : in out Parse_Line_Context)
   is
      Scope_State renames Context.Scope;
      Declaration_Targets renames Context.Declaration_Targets;
      Profile_State renames Context.Profile;
      Executable_Binding renames Context.Executable_Binding;
      Source_Recovery renames Context.Source_Recovery;

      Depth           : Natural renames Scope_State.Depth;
      Pending_Generic : Boolean renames Declaration_Targets.Pending_Generic;
      In_Record       : Boolean renames Scope_State.In_Record;
      Pending_Discriminants : Boolean renames Declaration_Targets.Pending_Discriminants;
      Pending_Discriminant_Owner : Symbol_Id renames Declaration_Targets.Pending_Discriminant_Owner;
      Pending_Type_Header_Owner : Symbol_Id renames Declaration_Targets.Pending_Type_Header_Owner;
      Pending_Record_After_Is_Owner : Symbol_Id renames Declaration_Targets.Pending_Record_After_Is_Owner;
      Pending_Concurrent_Header_Owner : Symbol_Id renames Declaration_Targets.Pending_Concurrent_Header_Owner;
      Pending_Array_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Array_Target_Owner;
      Pending_Access_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Access_Target_Owner;
      Pending_Access_Subprogram_Profile_Owner : Symbol_Id renames Declaration_Targets.Pending_Access_Subprogram_Profile_Owner;
      Pending_Return_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Return_Target_Owner;
      Pending_Return_Access_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Return_Access_Target_Owner;
      Pending_Subtype_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Subtype_Target_Owner;
      Pending_Derived_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Derived_Target_Owner;
      Pending_Interface_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Interface_Target_Owner;
      Pending_Declaration_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Declaration_Target_Owner;
      Pending_Generic_Formal_Package_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Generic_Formal_Package_Target_Owner;
      Pending_Generic_Formal_Subprogram_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Generic_Formal_Subprogram_Target_Owner;
      Pending_Object_Array_Target_Owners : Collected_Symbol_List renames Declaration_Targets.Pending_Object_Array_Target_Owners;
      Pending_Object_Array_Target_Count  : Natural renames Declaration_Targets.Pending_Object_Array_Target_Count;
      Pending_Object_Access_Target_Owners : Collected_Symbol_List renames Declaration_Targets.Pending_Object_Access_Target_Owners;
      Pending_Object_Access_Target_Count  : Natural renames Declaration_Targets.Pending_Object_Access_Target_Count;
      Pending_Object_Access_Subprogram_Profile_Owners : Collected_Symbol_List renames Declaration_Targets.Pending_Object_Access_Subprogram_Profile_Owners;
      Pending_Object_Access_Subprogram_Profile_Count  : Natural renames Declaration_Targets.Pending_Object_Access_Subprogram_Profile_Count;
      Pending_Generic_Formal_Object_Target_Owners : Collected_Symbol_List renames Declaration_Targets.Pending_Generic_Formal_Object_Target_Owners;
      Pending_Generic_Formal_Object_Target_Count  : Natural renames Declaration_Targets.Pending_Generic_Formal_Object_Target_Count;
      Pending_Profile_Access_Target_Owners : Collected_Symbol_List renames Profile_State.Pending_Profile_Access_Target_Owners;
      Pending_Profile_Access_Target_Count  : Natural renames Profile_State.Pending_Profile_Access_Target_Count;
      Pending_Enumeration : Boolean renames Executable_Binding.Pending_Enumeration;
      Pending_Enumeration_Owner : Symbol_Id renames Executable_Binding.Pending_Enumeration_Owner;
      Pending_Profile : Boolean renames Profile_State.Pending_Profile;
      Pending_Profile_Owner : Symbol_Id renames Profile_State.Pending_Profile_Owner;
      Pending_Body_Owner : Symbol_Id renames Executable_Binding.Pending_Body_Owner;
      No_Comment : constant String := Editor.Ada_Syntax_Core.Strip_Comment_Safely (Raw_Line);
      Trimmed    : constant String := Trim (No_Comment);
      Lower_Line : constant String := Lower (Trimmed);
      Decl       : constant String := Strip_Prefixes (Trimmed);
      Raw_Decl   : constant String := Strip_Prefixes (Trim (Raw_Line));
      Decl_Lower : constant String := Lower (Decl);
      Phase_State : Parse_Line_Phase_State;
      Name        renames Phase_State.Name;
      Name_Len    renames Phase_State.Name_Len;
      Kind        renames Phase_State.Kind;
      Flags       renames Phase_State.Flags;
      Target      renames Phase_State.Target;
      Target_Len  renames Phase_State.Target_Len;
      Profile     renames Phase_State.Profile;
      Profile_Len renames Phase_State.Profile_Len;

      procedure Set_Target (S : String) is
      begin
         Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Set_Target
           (Phase_State, S);
      end Set_Target;

      function Current_Name return String is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Name_Text
           (Phase_State);
      end Current_Name;

      function Current_Target return String is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Target_Text
           (Phase_State);
      end Current_Target;

      function Current_Profile return String is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Profile_Text
           (Phase_State);
      end Current_Profile;

      function Current_Parent return Symbol_Id is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase.Current_Parent
           (Scope_State);
      end Current_Parent;

      function Current_Private return Boolean is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase.Current_Private
           (Scope_State);
      end Current_Private;

      function Starts_With_Declaration_Or_Metadata return Boolean is
      begin
         return Line_Dispatch.Starts_With_Declaration_Or_Metadata
           (Decl_Lower);
      end Starts_With_Declaration_Or_Metadata;

      function Emit return Symbol_Id is
         Col : constant Positive := First_Non_Blank_Column (Raw_Line);
         Parent : constant Symbol_Id := Current_Parent;
         Final_Kind : Symbol_Kind := Kind;
      begin
         if Name_Len = 0 then
            return No_Symbol;
         end if;
         if Pending_Generic then
            Flags.Is_Generic := True;
            if Kind = Symbol_Generic_Formal_Type
              or else Kind = Symbol_Generic_Formal_Object
              or else Kind = Symbol_Generic_Formal_Subprogram
              or else Kind = Symbol_Generic_Formal_Package
            then
               null;
            elsif Kind = Symbol_Package then
               Final_Kind := Symbol_Generic_Package;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Consume_Generic_Unit (Declaration_Targets);
            elsif Kind = Symbol_Procedure or else Kind = Symbol_Function or else Kind = Symbol_Operator_Function then
               Final_Kind := Symbol_Generic_Subprogram;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Consume_Generic_Unit (Declaration_Targets);
            else
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Consume_Generic_Unit (Declaration_Targets);
            end if;
         end if;

         if Flags.Is_Separate
           and then Has_Token (Decl_Lower, "is")
           and then not Has_Code_Char (Decl_Lower, ';')
           and then not Flags.Is_Rename
           and then not Flags.Is_Instantiation
           and then (Kind = Symbol_Package_Body
                     or else Kind = Symbol_Procedure
                     or else Kind = Symbol_Function
                     or else Kind = Symbol_Operator_Function
                     or else Kind = Symbol_Task
                     or else Kind = Symbol_Protected)
         then
            --  Keep explicit separate-body metadata in the shared model.
            --  The original callable/package/task kind is still visible from
            --  source spelling/profile/target, while Outline can render this
            --  as a subunit body and navigation can link it to Target_Name.
            Final_Kind := Symbol_Separate_Body;
         end if;

         declare
            New_Id : constant Symbol_Id := Add_Symbol
              (Analysis, Current_Name, Final_Kind,
               (Line_Number, Col, Line_Number, Positive'Max (Col, Col + Name_Len - 1)),
               Col, Enclosing_Scope => Scope_Id (Natural (Parent)),
               Parent_Symbol => Parent, Depth => Depth,
               Profile_Summary => Current_Profile,
               Flags => Flags,
               Target_Name => Current_Target);
         begin
            return New_Id;
         end;
      end Emit;


      procedure Parse_Compact_Scope_Tail (Owner : Symbol_Id) is
         Code       : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
         Lower_Code : constant String (Code'Range) := Lower (Code);
         Nesting    : Natural := 0;
         Is_Start   : Natural := 0;
         Is_End     : Natural := 0;
      begin
         for I in Code'Range loop
            if Code (I) = '(' then
               Nesting := Nesting + 1;
            elsif Code (I) = ')' then
               if Nesting > 0 then
                  Nesting := Nesting - 1;
               end if;
            elsif Nesting = 0
              and then I + 1 <= Code'Last
              and then Lower_Code (I .. I + 1) = "is"
              and then (I = Code'First or else not Is_Word_Char (Lower_Code (I - 1)))
              and then (I + 2 > Code'Last or else not Is_Word_Char (Lower_Code (I + 2)))
            then
               Is_Start := I;
               Is_End := I + 1;
               exit;
            end if;
         end loop;

         if Is_Start = 0 or else Is_End >= Raw_Line'Last then
            return;
         end if;

         declare
            Tail_Line : String := Raw_Line;
         begin
            for I in Tail_Line'First .. Is_End loop
               Tail_Line (I) := ' ';
            end loop;

            if Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line))'Length = 0 then
               return;
            end if;

            declare
               Local_Context : Parse_Line_Context := Context;

               function Owner_Is_Callable return Boolean is
               begin
                  if Owner = No_Symbol then
                     return False;
                  end if;

                  declare
                     Info : constant Symbol_Info := Symbol (Analysis, Owner);
                  begin
                     return Info.Kind in Symbol_Procedure | Symbol_Function | Symbol_Operator_Function;
                  end;
               end Owner_Is_Callable;

               procedure Parse_Tail_Segment
                 (First : Natural;
                  Last  : Natural)
               is
                  Segment_Line : String := (Raw_Line'Range => ' ');
                  Segment_Code : constant String :=
                    Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line (First .. Last));
                  Segment_Text : constant String := Trim (Segment_Code);
                  Segment_Lower : constant String := Lower (Segment_Text);
               begin
                  if First > Last or else Segment_Text'Length = 0 then
                     return;
                  end if;

                  if Segment_Lower = "private"
                    or else Segment_Lower = "private;"
                  then
                     --  Compact one-line package specs can contain a private
                     --  section marker after one or more public declarations:
                     --     package P is A : Integer; private; B : Integer; end P;
                     --  Parse following tail segments with the local scope
                     --  marked private, while keeping all state local to this
                  --  same-line scope-tail parse.
                     Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
                       .Mark_Current_Private (Local_Context.Scope);
                     return;
                  elsif Segment_Lower'Length >= 3
                    and then Starts_With_Word (Segment_Lower, "end")
                  then
                     return;
                  elsif Owner_Is_Callable
                    and then
                      ((Contains (Segment_Lower, "return ")
                        and then Contains (Segment_Lower, " end return"))
                       or else (Contains (Segment_Lower, "return ")
                                and then Contains (Segment_Lower, ":")
                                and then Contains (Segment_Lower, " do"))
                       or else Contains (Segment_Lower, ": declare")
                     or else Contains (Segment_Lower, ": begin"))
                  then
                     return;
                  end if;

                  Segment_Line (First .. Last) := Raw_Line (First .. Last);

                  if Owner_Is_Callable then
                     loop
                        declare
                           Segment_Code : constant String :=
                             Editor.Ada_Syntax_Core.Sanitize_Line (Segment_Line);
                           Segment_Text : constant String := Trim (Segment_Code);
                           Segment_Lower : constant String := Lower (Segment_Text);
                           First_Code : Natural := 0;
                           Blank_Last : Natural := 0;
                        begin
                           if Segment_Text'Length = 0 then
                              return;
                           elsif Starts_With_Word (Segment_Lower, "begin") then
                              Blank_Last := Segment_Text'First + 4;
                           elsif Starts_With_Word (Segment_Lower, "declare") then
                              Blank_Last := Segment_Text'First + 6;
                           elsif Starts_With_Word (Segment_Lower, "end")
                             or else Starts_With_Word (Segment_Lower, "null")
                             or else Starts_With_Word (Segment_Lower, "if")
                             or else Starts_With_Word (Segment_Lower, "case")
                             or else Starts_With_Word (Segment_Lower, "loop")
                             or else Starts_With_Word (Segment_Lower, "elsif")
                             or else Starts_With_Word (Segment_Lower, "else")
                           then
                              return;
                           else
                              exit;
                           end if;

                           for Pos in Segment_Line'Range loop
                              if Segment_Code (Pos) /= ' ' then
                                 First_Code := Pos;
                                 exit;
                              end if;
                           end loop;

                           if First_Code = 0 then
                              return;
                           end if;

                           for Pos in First_Code .. First_Code + (Blank_Last - Segment_Text'First) loop
                              Segment_Line (Pos) := ' ';
                           end loop;
                        end;
                     end loop;
                  end if;

                  Parse_Line (Analysis, Segment_Line, Line_Number, Local_Context);
               end Parse_Tail_Segment;

               Segment_Start : Natural := Is_End + 1;
               Tail_Nesting  : Natural := 0;
               Record_Nesting : Natural := 0;
               Compact_Scope_Nesting : Natural := 0;
               Callable_Body_Nesting : Natural := 0;
               Concurrent_Scope_Nesting : Natural := 0;
               Anonymous_Block_Nesting : Natural := 0;
               Max_Compact_Callable_Nesting : constant Natural := 16;
               Max_Anonymous_Block_Name_Length : constant Natural := 80;
               type Anonymous_Block_Name_Array is
                 array (Positive range 1 .. Max_Compact_Callable_Nesting) of
                   String (1 .. Max_Anonymous_Block_Name_Length);
               type Anonymous_Block_Name_Length_Array is
                 array (Positive range 1 .. Max_Compact_Callable_Nesting) of Natural;
               Anonymous_Block_Names : Anonymous_Block_Name_Array :=
                 (others => (others => ' '));
               Anonymous_Block_Name_Lengths : Anonymous_Block_Name_Length_Array :=
                 (others => 0);
               Max_Compact_Callable_Name_Length : constant Natural := 80;
               type Compact_Callable_Begin_Array is
                 array (Positive range 1 .. Max_Compact_Callable_Nesting) of Boolean;
               Callable_Body_Begin_Seen : Compact_Callable_Begin_Array :=
                 (others => False);
               type Compact_Callable_Name_Array is
                 array (Positive range 1 .. Max_Compact_Callable_Nesting) of
                   String (1 .. Max_Compact_Callable_Name_Length);
               type Compact_Callable_Name_Length_Array is
                 array (Positive range 1 .. Max_Compact_Callable_Nesting) of Natural;
               Callable_Body_Names : Compact_Callable_Name_Array :=
                 (others => (others => ' '));
               Callable_Body_Name_Lengths : Compact_Callable_Name_Length_Array :=
                 (others => 0);
               Concurrent_Scope_Names : Compact_Callable_Name_Array :=
                 (others => (others => ' '));
               Concurrent_Scope_Name_Lengths : Compact_Callable_Name_Length_Array :=
                 (others => 0);
               Concurrent_Scope_Begin_Seen : Compact_Callable_Begin_Array :=
                 (others => False);
               Compact_Scope_Names : Compact_Callable_Name_Array :=
                 (others => (others => ' '));
               Compact_Scope_Name_Lengths : Compact_Callable_Name_Length_Array :=
                 (others => 0);
               Compact_Scope_Begin_Seen : Compact_Callable_Begin_Array :=
                 (others => False);
               Tail_Code     : constant String :=
                 Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line);
               Tail_Lower    : constant String (Tail_Code'Range) := Lower (Tail_Code);

               function Tail_Token_At
                 (Pos   : Natural;
                  Token : String) return Boolean
               is
               begin
                  return Tail_Analysis_Helpers.Tail_Token_At (Tail_Lower, Pos, Token);
               end Tail_Token_At;

               function Previous_Token_Is_End (Pos : Natural) return Boolean is
               begin
                  return Tail_Analysis_Helpers.Previous_Token_Is_End (Tail_Lower, Pos);
               end Previous_Token_Is_End;

               function End_Followed_By
                 (Pos   : Natural;
                  Token : String) return Boolean
               is
               begin
                  return Tail_Analysis_Helpers.End_Followed_By (Tail_Lower, Pos, Token);
               end End_Followed_By;

               function Compact_Package_Name_At
                 (Pos : Natural) return String;

               function End_Is_Metadata_Or_Control (Pos : Natural) return Boolean is
               begin
                  return Tail_Analysis_Helpers.Generic_End_Is_Metadata_Or_Control
                    (Tail_Lower, Pos);
               end End_Is_Metadata_Or_Control;

               function Has_Nested_Compact_Scope_Opener
                 (Pos : Natural) return Boolean
               is
               begin
                  return Tail_Analysis_Helpers.Has_Nested_Compact_Scope_Opener
                    (Tail_Lower, Pos);
               end Has_Nested_Compact_Scope_Opener;

               function Is_Selected_Name_Char (C : Character) return Boolean is
               begin
                  --  compact nested package bodies can use selected
                  --  names.  Keep the full selected package name so an inner
                  --  same-prefix terminator such as ``end Parent;`` cannot
                  --  close ``package body Parent.Child is`` before the exact
                  --  ``end Parent.Child;`` marker.
                  return Is_Word_Char (C) or else C = '.';
               end Is_Selected_Name_Char;

               function Is_Selected_Name_Blank (C : Character) return Boolean
                 renames Tail_Analysis_Helpers.Is_Selected_Name_Blank;

               function Compact_Selected_Name_At (Pos : Natural) return String is
               begin
                  return Tail_Analysis_Helpers.Compact_Selected_Name_At
                    (Tail_Lower, Pos);
               end Compact_Selected_Name_At;

               procedure Push_Anonymous_Block_Name (Name : String) is
                  Store_Len : constant Natural :=
                    Natural'Min (Name'Length, Max_Anonymous_Block_Name_Length);
               begin
                  Anonymous_Block_Nesting := Anonymous_Block_Nesting + 1;
                  if Anonymous_Block_Nesting in 1 .. Max_Compact_Callable_Nesting then
                     Anonymous_Block_Name_Lengths (Anonymous_Block_Nesting) := Store_Len;
                     Anonymous_Block_Names (Anonymous_Block_Nesting) := (others => ' ');
                     if Store_Len > 0 then
                        Anonymous_Block_Names (Anonymous_Block_Nesting) (1 .. Store_Len) :=
                          Name (Name'First .. Name'First + Store_Len - 1);
                     end if;
                  end if;
               end Push_Anonymous_Block_Name;

               function Previous_Selected_Name_Before
                 (Pos : Natural) return String
               is
               begin
                  return Tail_Analysis_Helpers.Previous_Selected_Name_Before
                    (Tail_Lower, Pos);
               end Previous_Selected_Name_Before;

               function Anonymous_Declare_Name_At (Pos : Natural) return String is
               begin
                  return Tail_Analysis_Helpers.Anonymous_Declare_Name_At
                    (Tail_Lower, Pos);
               end Anonymous_Declare_Name_At;

               function Anonymous_Begin_Name_At (Pos : Natural) return String is
                  J : Natural := Pos;
               begin
                  --  a bare block may be labelled as
                  --  ``Name : begin ... end Name;``.  The compact tail
                  --  splitter must remember that label; otherwise the named
                  --  block end is not consumed as the anonymous inner block
                  --  terminator and can keep the surrounding callable/package
                  --  tail open past its real end.
                  if Pos <= Tail_Lower'First then
                     return "";
                  end if;

                  J := Pos - 1;
                  while J >= Tail_Lower'First and then Is_Selected_Name_Blank (Tail_Lower (J)) loop
                     exit when J = Tail_Lower'First;
                     J := J - 1;
                  end loop;

                  if J >= Tail_Lower'First and then Tail_Lower (J) = ':' then
                     return Previous_Selected_Name_Before (J);
                  else
                     return "";
                  end if;
               end Anonymous_Begin_Name_At;

               function Anonymous_Accept_Name_At (Pos : Natural) return String is
                  J : Natural := Pos + 6;
               begin
                  while J <= Tail_Lower'Last and then Is_Selected_Name_Blank (Tail_Lower (J)) loop
                     J := J + 1;
                  end loop;

                  if J <= Tail_Lower'Last and then Is_Word_Char (Tail_Lower (J)) then
                     return Compact_Selected_Name_At (J);
                  else
                     return "";
                  end if;
               end Anonymous_Accept_Name_At;

               function End_Matches_Anonymous_Block (Pos : Natural) return Boolean is
                  J : Natural := Pos + 3;
                  Expected_Len : Natural;
               begin
                  if Anonymous_Block_Nesting = 0
                    or else Anonymous_Block_Nesting > Max_Compact_Callable_Nesting
                  then
                     return True;
                  end if;

                  Expected_Len := Anonymous_Block_Name_Lengths (Anonymous_Block_Nesting);
                  while J <= Tail_Lower'Last and then Is_Selected_Name_Blank (Tail_Lower (J)) loop
                     J := J + 1;
                  end loop;

                  if Expected_Len = 0 then
                     return J > Tail_Lower'Last or else Tail_Lower (J) = ';';
                  elsif J <= Tail_Lower'Last and then Is_Word_Char (Tail_Lower (J)) then
                     declare
                        Found : constant String := Compact_Selected_Name_At (J);
                     begin
                        return Found'Length = Expected_Len
                          and then Found =
                            Anonymous_Block_Names (Anonymous_Block_Nesting) (1 .. Expected_Len);
                     end;
                  else
                     return False;
                  end if;
               end End_Matches_Anonymous_Block;

               procedure Pop_Anonymous_Block_Name is
               begin
                  if Anonymous_Block_Nesting in 1 .. Max_Compact_Callable_Nesting then
                     Anonymous_Block_Name_Lengths (Anonymous_Block_Nesting) := 0;
                     Anonymous_Block_Names (Anonymous_Block_Nesting) := (others => ' ');
                  end if;
                  Anonymous_Block_Nesting := Anonymous_Block_Nesting - 1;
               end Pop_Anonymous_Block_Name;

               function Compact_Package_Name_At
                 (Pos : Natural) return String
               is
               begin
                  return Tail_Analysis_Helpers.Compact_Package_Name_At
                    (Tail_Lower, Pos);
               end Compact_Package_Name_At;

               procedure Push_Compact_Scope_Name (Name : String) is
                  Store_Len : constant Natural :=
                    Natural'Min (Name'Length, Max_Compact_Callable_Name_Length);
               begin
                  if Compact_Scope_Nesting in 1 .. Max_Compact_Callable_Nesting then
                     Compact_Scope_Name_Lengths (Compact_Scope_Nesting) := Store_Len;
                     Compact_Scope_Names (Compact_Scope_Nesting) := (others => ' ');
                     if Store_Len > 0 then
                        Compact_Scope_Names (Compact_Scope_Nesting) (1 .. Store_Len) :=
                          Name (Name'First .. Name'First + Store_Len - 1);
                     end if;
                  end if;
               end Push_Compact_Scope_Name;

               function End_Matches_Compact_Scope
                 (Pos : Natural) return Boolean
               is
                  J : Natural := Pos + 3;
                  Name_Start : Natural;
                  Name_Last  : Natural;
                  Expected_Len : Natural;
               begin
                  if Compact_Scope_Nesting = 0
                    or else Compact_Scope_Nesting > Max_Compact_Callable_Nesting
                  then
                     return True;
                  end if;

                  Expected_Len := Compact_Scope_Name_Lengths (Compact_Scope_Nesting);
                  if Expected_Len = 0 then
                     return True;
                  end if;

                  while J <= Tail_Lower'Last
                    and then (Tail_Lower (J) = ' '
                              or else Tail_Lower (J) = Ada.Characters.Latin_1.HT)
                  loop
                     J := J + 1;
                  end loop;

                  --  A compact nested package may contain callable, record,
                  --  concurrent, or statement terminators before the package's
                  --  own end marker.  Anonymous ``end;`` is accepted, but a
                  --  named end must match the package opener before the outer
                  --  package-tail splitter resumes.
                  if J > Tail_Lower'Last or else Tail_Lower (J) = ';' then
                     return Expected_Len = 0;
                  elsif Is_Word_Char (Tail_Lower (J)) then
                     declare
                        Found : constant String := Compact_Selected_Name_At (J);
                     begin
                        return Found'Length = Expected_Len
                          and then Found =
                            Compact_Scope_Names (Compact_Scope_Nesting) (1 .. Expected_Len);
                     end;
                  else
                     return True;
                  end if;
               end End_Matches_Compact_Scope;

               function Compact_Callable_Name_At
                 (Pos : Natural) return String
               is
               begin
                  return Tail_Analysis_Helpers.Compact_Callable_Name_At
                    (Tail_Lower, Pos);
               end Compact_Callable_Name_At;

               procedure Emit_Local_Compact_Callable (Pos : Natural) is
                  Is_Function : constant Boolean := Tail_Token_At (Pos, "function");
                  Name_Text   : constant String :=
                    (if Is_Function then Read_Function_Name (Tail_Line, Pos + 8, True)
                     else Read_Name (Tail_Line, Pos + 9, True));
                  Kind        : constant Symbol_Kind :=
                    (if Is_Function then
                       (if Name_Text'Length > 0 and then Name_Text (Name_Text'First) = '"' then
                          Symbol_Operator_Function
                        else
                          Symbol_Function)
                     else
                       Symbol_Procedure);
                  Name_Pos    : constant Natural :=
                    (if Name_Text'Length = 0 then 0
                     else Ada.Strings.Fixed.Index (Tail_Line (Pos .. Tail_Line'Last), Name_Text));
                  Col         : constant Positive :=
                    (if Name_Pos = 0 then Positive (Pos - Raw_Line'First + 1)
                     else Positive (Name_Pos - Raw_Line'First + 1));
                  Local_Flags : Declaration_Flags :=
                    (Is_Private =>
                       Local_Context.Scope.Private_Stack
                         (Local_Context.Scope.Depth),
                     Is_Body    => True,
                     others     => False);
                  Profile_Text : constant String :=
                    (if Name_Text'Length = 0 then ""
                     else Profile_From (Tail_Line, Name_Text));
                  Target_Text  : constant String :=
                    (if Is_Function then Function_Return_Target (Tail_Line (Pos .. Tail_Line'Last))
                     else "");
                  New_Id       : Symbol_Id;
               begin
                  if Name_Text'Length = 0 then
                     return;
                  end if;

                  New_Id := Add_Symbol
                    (Analysis, Name_Text, Kind,
                     (Line_Number, Col, Line_Number,
                      Positive'Max (Col, Col + Name_Text'Length - 1)),
                     Col, Enclosing_Scope => Scope_Id (Natural (Owner)),
                     Parent_Symbol => Owner, Depth => Local_Context.Scope.Depth,
                     Profile_Summary => Profile_Text,
                     Flags => Local_Flags,
                     Target_Name => Target_Text);

                  if New_Id /= No_Symbol then
                     Add_Profile_Parameter_Names
                       (Analysis, Tail_Line, Line_Number,
                        Local_Context.Scope.Depth + 1, New_Id,
                        Name_Text,
                        Local_Context.Profile.Pending_Profile_Access_Target_Owners,
                        Local_Context.Profile.Pending_Profile_Access_Target_Count);
                  end if;
               end Emit_Local_Compact_Callable;

               procedure Push_Compact_Callable_Name (Name : String) is
                  Store_Len : constant Natural :=
                    Natural'Min (Name'Length, Max_Compact_Callable_Name_Length);
               begin
                  if Callable_Body_Nesting in 1 .. Max_Compact_Callable_Nesting then
                     Callable_Body_Name_Lengths (Callable_Body_Nesting) := Store_Len;
                     Callable_Body_Begin_Seen (Callable_Body_Nesting) := False;
                     Callable_Body_Names (Callable_Body_Nesting) := (others => ' ');
                     if Store_Len > 0 then
                        Callable_Body_Names (Callable_Body_Nesting) (1 .. Store_Len) :=
                          Name (Name'First .. Name'First + Store_Len - 1);
                     end if;
                  end if;
               end Push_Compact_Callable_Name;

               function End_Matches_Compact_Callable
                 (Pos : Natural) return Boolean
               is
                  J : Natural := Pos + 3;
                  Name_Start : Natural;
                  Name_Last  : Natural;
                  Expected_Len : Natural;
               begin
                  if Callable_Body_Nesting = 0
                    or else Callable_Body_Nesting > Max_Compact_Callable_Nesting
                  then
                     return True;
                  end if;

                  Expected_Len := Callable_Body_Name_Lengths (Callable_Body_Nesting);
                  if Expected_Len = 0 then
                     return True;
                  end if;

                  while J <= Tail_Lower'Last
                    and then (Tail_Lower (J) = ' '
                              or else Tail_Lower (J) = Ada.Characters.Latin_1.HT)
                  loop
                     J := J + 1;
                  end loop;

                  --  A named compact callable body must close at its matching
                  --  named end.  Anonymous ``end;`` markers inside its body
                  --  belong to nested blocks and must not reopen the
                  --  enclosing package tail early.  A named ``end Some_Block;``
                  --  inside the callable body is
                  --  not.  Keep the compact callable region open unless the
                  --  optional name matches the callable opener.  --  extends this to selected-name child-unit subprogram
                  --  bodies, so ``procedure Parent.Child is`` closes only at
                  --  ``end Parent.Child;`` and not at an inner ``end Parent;``.
                  if J > Tail_Lower'Last or else Tail_Lower (J) = ';' then
                     return Expected_Len = 0;
                  elsif Tail_Lower (J) = '"' then
                     Name_Start := J;
                     Name_Last := J + 1;
                     while Name_Last <= Tail_Lower'Last
                       and then Tail_Lower (Name_Last) /= '"'
                     loop
                        Name_Last := Name_Last + 1;
                     end loop;
                  elsif Is_Word_Char (Tail_Lower (J)) then
                     declare
                        Found : constant String := Compact_Selected_Name_At (J);
                     begin
                        return Found'Length = Expected_Len
                          and then Found =
                            Callable_Body_Names (Callable_Body_Nesting) (1 .. Expected_Len);
                     end;
                  else
                     return True;
                  end if;

                  return Name_Last - Name_Start + 1 = Expected_Len
                    and then Tail_Lower (Name_Start .. Name_Last) =
                      Callable_Body_Names (Callable_Body_Nesting) (1 .. Expected_Len);
               end End_Matches_Compact_Callable;


               function Compact_Concurrent_Name_At
                 (Pos : Natural) return String
               is
                  J : Natural := Pos;
                  Last_Name : Natural;
               begin
                  if Tail_Token_At (Pos, "protected") then
                     J := Pos + 9;
                  elsif Tail_Token_At (Pos, "task") then
                     J := Pos + 4;
                  else
                     return "";
                  end if;

                  while J <= Tail_Lower'Last
                    and then (Tail_Lower (J) = ' '
                              or else Tail_Lower (J) = Ada.Characters.Latin_1.HT)
                  loop
                     J := J + 1;
                  end loop;

                  if Tail_Token_At (J, "body") then
                     J := J + 4;
                     while J <= Tail_Lower'Last
                       and then (Tail_Lower (J) = ' '
                                 or else Tail_Lower (J) = Ada.Characters.Latin_1.HT)
                     loop
                        J := J + 1;
                     end loop;
                  end if;

                  if Tail_Token_At (J, "type") then
                     J := J + 4;
                     while J <= Tail_Lower'Last
                       and then (Tail_Lower (J) = ' '
                                 or else Tail_Lower (J) = Ada.Characters.Latin_1.HT)
                     loop
                        J := J + 1;
                     end loop;
                  end if;

                  return Compact_Selected_Name_At (J);
               end Compact_Concurrent_Name_At;

               procedure Push_Compact_Concurrent_Name (Name : String) is
                  Store_Len : constant Natural :=
                    Natural'Min (Name'Length, Max_Compact_Callable_Name_Length);
               begin
                  if Concurrent_Scope_Nesting in 1 .. Max_Compact_Callable_Nesting then
                     Concurrent_Scope_Name_Lengths (Concurrent_Scope_Nesting) := Store_Len;
                     Concurrent_Scope_Names (Concurrent_Scope_Nesting) := (others => ' ');
                     if Store_Len > 0 then
                        Concurrent_Scope_Names (Concurrent_Scope_Nesting) (1 .. Store_Len) :=
                          Name (Name'First .. Name'First + Store_Len - 1);
                     end if;
                  end if;
               end Push_Compact_Concurrent_Name;

               function End_Matches_Compact_Concurrent
                 (Pos : Natural) return Boolean
               is
                  J : Natural := Pos + 3;
                  Name_Start : Natural;
                  Name_Last  : Natural;
                  Expected_Len : Natural;
               begin
                  if Concurrent_Scope_Nesting = 0
                    or else Concurrent_Scope_Nesting > Max_Compact_Callable_Nesting
                  then
                     return True;
                  end if;

                  Expected_Len := Concurrent_Scope_Name_Lengths (Concurrent_Scope_Nesting);
                  if Expected_Len = 0 then
                     return True;
                  end if;

                  while J <= Tail_Lower'Last
                    and then (Tail_Lower (J) = ' '
                              or else Tail_Lower (J) = Ada.Characters.Latin_1.HT)
                  loop
                     J := J + 1;
                  end loop;

                  if J > Tail_Lower'Last or else Tail_Lower (J) = ';' then
                     return True;
                  elsif Is_Word_Char (Tail_Lower (J)) then
                     declare
                        Found : constant String := Compact_Selected_Name_At (J);
                     begin
                        --  protected/task bodies can also be selected child
                        --  units in compact package tails.  Match the full selected
                        --  name so ``protected body Parent.Lock is`` cannot close at
                        --  an inner same-prefix terminator such as ``end Parent;``.
                        return Found'Length = Expected_Len
                          and then Found =
                            Concurrent_Scope_Names (Concurrent_Scope_Nesting) (1 .. Expected_Len);
                     end;
                  else
                     return True;
                  end if;
               end End_Matches_Compact_Concurrent;
               function Has_Nested_Compact_Callable_Body_Opener
                 (Pos : Natural) return Boolean
               is
                  J : Natural := Pos;
                  Saw_Is : Boolean := False;
                  Header_Nesting : Natural := 0;
               begin
                  --  Compact package bodies may contain one-line or condensed
                  --  nested subprogram bodies.  Their declarative/body regions
                  --  may contain semicolons that are not package-tail
                  --  separators.  Keep the nested callable body whole until
                  --  its matching end so locals/body statements are not
                  --  emitted as package-level declarations.  A profile can
                  --  itself contain semicolon-separated parameter groups, so
                  --  scan the callable header using delimiter depth before
                  --  deciding that a semicolon ends the declaration header.
                  --  keeps compact expression functions and null/body
                  --  stubs out of this nesting path: they terminate at their
                  --  own semicolon and do not have a following matching end.
                  if not (Tail_Token_At (Pos, "procedure")
                          or else Tail_Token_At (Pos, "function"))
                  then
                     return False;
                  end if;

                  --  malformed/in-progress compact callable text
                  --  such as ``procedure is ...`` must not open an anonymous
                  --  callable region in the enclosing package-tail splitter.
                  --  Without a real callable name, a later anonymous ``end;``
                  --  could close the synthetic region and make subsequent
                  --  declarations appear under the wrong owner.  Degrade by
                  --  leaving the malformed header as ordinary tail text.
                  declare
                     Candidate_Name : constant String := Compact_Callable_Name_At (Pos);
                  begin
                     if Is_Invalid_Compact_Owner_Name (Candidate_Name) then
                        return False;
                     end if;
                  end;

                  if Pos > Tail_Lower'First + 4
                    and then Tail_Lower (Pos - 5 .. Pos - 1) = "with "
                  then
                     return False;
                  end if;

                  while J <= Tail_Lower'Last loop
                     if Tail_Lower (J) = '(' then
                        Header_Nesting := Header_Nesting + 1;
                     elsif Tail_Lower (J) = ')' then
                        if Header_Nesting > 0 then
                           Header_Nesting := Header_Nesting - 1;
                        end if;
                     elsif Tail_Lower (J) = ';' and then Header_Nesting = 0 then
                        exit;
                     end if;

                     if Header_Nesting = 0 then
                        if Tail_Token_At (J, "renames")
                          or else Tail_Token_At (J, "new")
                        then
                           return False;
                        elsif Tail_Token_At (J, "is") then
                           declare
                              After_Is : constant Natural :=
                                Lexical_Helpers.Next_Non_Blank (Tail_Lower, J + 2);
                           begin
                              Saw_Is := True;
                              if After_Is <= Tail_Lower'Last
                                and then Tail_Lower (After_Is) = '('
                              then
                                 return False;
                              elsif Tail_Token_At (After_Is, "null")
                                or else Tail_Token_At (After_Is, "separate")
                              then
                                 return False;
                              end if;
                           end;
                        end if;
                     end if;

                     J := J + 1;
                  end loop;

                  return Saw_Is;
               end Has_Nested_Compact_Callable_Body_Opener;

               function Has_Nested_Compact_Concurrent_Scope_Opener
                 (Pos : Natural) return Boolean
               is
                  J : Natural := Pos;
                  Saw_Is : Boolean := False;
                  Header_Nesting : Natural := 0;
               begin
                  --  A compact protected/task declaration inside a one-line
                  --  package tail owns its own operation declarations.  Keep
                  --  the concurrent declaration whole so entries/subprograms
                  --  inside it are parsed under the concurrent symbol instead
                  --  of being split into the enclosing package.  The
                  --  protected/task header can contain a discriminant part
                  --  whose semicolon-separated groups are not package-tail
                  --  separators, so scan the header at delimiter depth zero
                  --  before deciding whether a semicolon ends the declaration
                  --  header.
                  if not (Tail_Token_At (Pos, "protected")
                          or else Tail_Token_At (Pos, "task"))
                  then
                     return False;
                  end if;

                  --  reject nameless compact protected/task fragments
                  --  before opening a concurrent-scope region.  This keeps
                  --  malformed source bounded and avoids a synthetic anonymous
                  --  concurrent owner swallowing following package-tail
                  --  declarations.
                  declare
                     Candidate_Name : constant String := Compact_Concurrent_Name_At (Pos);
                  begin
                     if Is_Invalid_Compact_Owner_Name (Candidate_Name) then
                        return False;
                     end if;
                  end;

                  while J <= Tail_Lower'Last loop
                     if Tail_Lower (J) = '(' then
                        Header_Nesting := Header_Nesting + 1;
                     elsif Tail_Lower (J) = ')' then
                        if Header_Nesting > 0 then
                           Header_Nesting := Header_Nesting - 1;
                        end if;
                     elsif Tail_Lower (J) = ';' and then Header_Nesting = 0 then
                        exit;
                     end if;

                     if Header_Nesting = 0
                       and then Tail_Token_At (J, "is")
                     then
                        Saw_Is := True;
                     end if;

                     J := J + 1;
                  end loop;

                  return Saw_Is;
               end Has_Nested_Compact_Concurrent_Scope_Opener;

               function Has_Accept_Do_Body (Pos : Natural) return Boolean is
                  J       : Natural := Pos;
                  Nesting : Natural := 0;
               begin
                  --  only ``accept ... do ... end`` owns an inner
                  --  anonymous end marker.  A compact ``accept Feed_Item;`` has no
                  --  matching end; treating it as anonymous-block nesting
                  --  would cause the surrounding compact callable/package tail
                  --  to miss its real end and swallow following declarations.
                  if not Tail_Token_At (Pos, "accept") then
                     return False;
                  end if;

                  while J <= Tail_Lower'Last loop
                     if Tail_Lower (J) = '(' then
                        Nesting := Nesting + 1;
                     elsif Tail_Lower (J) = ')' then
                        if Nesting > 0 then
                           Nesting := Nesting - 1;
                        end if;
                     elsif Tail_Lower (J) = ';' and then Nesting = 0 then
                        return False;
                     elsif Nesting = 0 and then Tail_Token_At (J, "do") then
                        return True;
                     end if;

                     J := J + 1;
                  end loop;

                  return False;
               end Has_Accept_Do_Body;
            begin
               Local_Context.Scope.Depth := Depth;
               Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
                 .Enter_Scope (Local_Context.Scope, Owner);

               --  One-line/package-generated Ada can put declarations after
               --  the scope-opening "is" and close the scope again on the
               --  same physical line.  Parse the tail segment-by-segment so a
               --  compact mid-tail "private;" marker affects only following
               --  declarations, while the caller's parser state remains
               --  untouched and same-line "end" text cannot leak scope or
               --  pending continuations into the following source line.  Keep
               --  compact nested records, packages, concurrent scopes, and callable bodies whole:
               --  internal semicolons are local to the nested declaration/body
               --  tail, not separators in the enclosing package scope.
               for I in Tail_Line'Range loop
                  if Tail_Line (I) = '(' then
                     Tail_Nesting := Tail_Nesting + 1;
                  elsif Tail_Line (I) = ')' then
                     if Tail_Nesting > 0 then
                        Tail_Nesting := Tail_Nesting - 1;
                     end if;
                  elsif Tail_Nesting = 0
                    and then Anonymous_Block_Nesting > 0
                    and then Tail_Token_At (I, "end")
                    and then (End_Is_Metadata_Or_Control (I)
                              or else End_Matches_Anonymous_Block (I))
                  then
                     --  compact anonymous ``declare`` blocks and
                     --  ``accept ... do`` bodies can contain control statements
                     --  before their own terminator.  Do not spend the
                     --  anonymous-block nesting level on inner ``end if`` /
                     --  ``end loop`` / metadata terminators; otherwise a later
                     --  anonymous ``end;`` can look like the surrounding
                     --  callable or package end and reopen the enclosing scope
                     --  too early.  adds a small name stack for
                     --  anonymous declare/accept bodies so a local compact
                     --  callable end such as ``end Local_Run;`` inside the
                     --  anonymous block cannot spend the anonymous block's own
                     --  later ``end;`` marker.  lets mismatched named
                     --  ends fall through so compact local callable ends still
                     --  close the callable stack.
                     if not End_Is_Metadata_Or_Control (I) then
                        Pop_Anonymous_Block_Name;
                     end if;
                  elsif Tail_Nesting = 0
                    and then Record_Nesting > 0
                    and then Tail_Token_At (I, "end")
                  then
                     --  nested compact records inside one-line
                     --  package tails may contain variant parts.  An inner
                     --  ``end case`` must not close the record nesting region
                     --  for the enclosing package-tail splitter; only the
                     --  matching ``end record`` does.
                     if End_Followed_By (I, "record") then
                        Record_Nesting := Record_Nesting - 1;
                     end if;
                  elsif Tail_Nesting = 0
                    and then Compact_Scope_Nesting > 0
                    and then Tail_Token_At (I, "end")
                    and then (End_Is_Metadata_Or_Control (I)
                              or else End_Matches_Compact_Scope (I))
                  then
                     --  a compact nested package can contain its
                     --  own compact callable/concurrent bodies or named block
                     --  terminators.  Do not close the nested package region
                     --  merely because an inner declaration says ``end Run;``;
                     --  resume the enclosing package splitter only at an
                     --  anonymous end or at the package's matching named end.
                     if not End_Is_Metadata_Or_Control (I) then
                        if Compact_Scope_Nesting <= Max_Compact_Callable_Nesting then
                           Compact_Scope_Name_Lengths (Compact_Scope_Nesting) := 0;
                           Compact_Scope_Begin_Seen (Compact_Scope_Nesting) := False;
                        end if;
                        Compact_Scope_Nesting := Compact_Scope_Nesting - 1;
                     end if;
                  elsif Tail_Nesting = 0
                    and then Callable_Body_Nesting > 0
                    and then Tail_Token_At (I, "end")
                  then
                     --  compact callable bodies inside one-line
                     --  package tails may declare compact record types,
                     --  including variant parts.  Their inner ``end record``
                     --  and ``end case`` markers must not close the callable
                     --  body nesting for the enclosing package-tail splitter;
                     --  otherwise local declarations after the record leak
                     --  into the package scope.
                     --  extends that protection to compact control
                     --  statements inside callable bodies.  Same-line
                     --  ``end if`` / ``end loop`` / ``end select`` markers
                     --  terminate statements, not the callable body, so they
                     --  must not reopen the enclosing package splitter early.
                     if not End_Is_Metadata_Or_Control (I)
                       and then End_Matches_Compact_Callable (I)
                     then
                        if Callable_Body_Nesting <= Max_Compact_Callable_Nesting then
                           Callable_Body_Name_Lengths (Callable_Body_Nesting) := 0;
                           Callable_Body_Begin_Seen (Callable_Body_Nesting) := False;
                        end if;
                        Callable_Body_Nesting := Callable_Body_Nesting - 1;
                     end if;
                  elsif Tail_Nesting = 0
                    and then Concurrent_Scope_Nesting > 0
                    and then Tail_Token_At (I, "end")
                  then
                     --  Apply the same protection to compact protected/task
                     --  tails: nested record/variant metadata and callable
                     --  operation bodies inside the concurrent declaration
                     --  must not terminate the concurrent region being kept
                     --  whole.  also keeps statement terminators
                     --  and operation/body names from reopening the enclosing
                     --  package-tail splitter before the protected/task
                     --  declaration's own end marker.
                     if not End_Is_Metadata_Or_Control (I)
                       and then End_Matches_Compact_Concurrent (I)
                     then
                        if Concurrent_Scope_Nesting <= Max_Compact_Callable_Nesting then
                           Concurrent_Scope_Name_Lengths (Concurrent_Scope_Nesting) := 0;
                           Concurrent_Scope_Begin_Seen (Concurrent_Scope_Nesting) := False;
                        end if;
                        Concurrent_Scope_Nesting := Concurrent_Scope_Nesting - 1;
                     end if;
                  elsif Tail_Nesting = 0
                    and then Callable_Body_Nesting > 0
                    and then Concurrent_Scope_Nesting = 0
                    and then Compact_Scope_Nesting = 0
                    and then Anonymous_Block_Nesting = 0
                    and then Tail_Token_At (I, "begin")
                  then
                     --  after a compact callable body's own begin
                     --  has been seen, a later bare ``begin ... end;`` inside
                     --  the same one-line callable is an anonymous block.  Keep
                     --  that inner anonymous ``end;`` from closing the compact
                     --  callable region before the callable's matching named
                     --  end marker.  The first begin belongs to the callable
                     --  body itself and is only recorded, not nested.  --  keeps this begin tracking on the innermost compact
                     --  owner: if the callable currently contains a compact
                     --  protected/task or nested package body, the begin belongs
                     --  to that inner owner and must not mark the enclosing
                     --  callable as having reached its own begin yet.
                     if Callable_Body_Nesting <= Max_Compact_Callable_Nesting then
                        if Callable_Body_Begin_Seen (Callable_Body_Nesting) then
                           Push_Anonymous_Block_Name (Anonymous_Begin_Name_At (I));
                        else
                           Callable_Body_Begin_Seen (Callable_Body_Nesting) := True;
                        end if;
                     end if;
                  elsif Tail_Nesting = 0
                    and then Concurrent_Scope_Nesting > 0
                    and then Compact_Scope_Nesting = 0
                    and then Anonymous_Block_Nesting = 0
                    and then Tail_Token_At (I, "begin")
                  then
                     --  compact protected/task bodies can contain
                     --  operation bodies and bare anonymous ``begin ... end;``
                     --  blocks on the same line.  The first begin seen while a
                     --  concurrent scope is being kept whole belongs to the
                     --  nested operation body; later bare begins are anonymous
                     --  blocks whose ``end;`` must not close the protected/task
                     --  scope before its matching end marker.  mirrors
                     --  the innermost-owner rule here: a protected/task region
                     --  nested inside a compact package body should not spend
                     --  the package body's own begin state.
                     if Concurrent_Scope_Nesting <= Max_Compact_Callable_Nesting then
                        if Concurrent_Scope_Begin_Seen (Concurrent_Scope_Nesting) then
                           Push_Anonymous_Block_Name (Anonymous_Begin_Name_At (I));
                        else
                           Concurrent_Scope_Begin_Seen (Concurrent_Scope_Nesting) := True;
                        end if;
                     end if;
                  elsif Tail_Nesting = 0
                    and then Compact_Scope_Nesting > 0
                    and then Anonymous_Block_Nesting = 0
                    and then Tail_Token_At (I, "begin")
                  then
                     --  compact nested package bodies can likewise
                     --  contain bare anonymous blocks after their own optional
                     --  begin.  Keep those inner anonymous ends from reopening
                     --  the enclosing package tail early.
                     if Compact_Scope_Nesting <= Max_Compact_Callable_Nesting then
                        if Compact_Scope_Begin_Seen (Compact_Scope_Nesting) then
                           Push_Anonymous_Block_Name (Anonymous_Begin_Name_At (I));
                        else
                           Compact_Scope_Begin_Seen (Compact_Scope_Nesting) := True;
                        end if;
                     end if;
                  elsif Tail_Nesting = 0
                    and then (Callable_Body_Nesting > 0
                              or else Concurrent_Scope_Nesting > 0
                              or else Compact_Scope_Nesting > 0)
                    and then (Tail_Token_At (I, "declare")
                              or else (Tail_Token_At (I, "accept")
                                       and then Has_Accept_Do_Body (I)))
                  then
                     if Tail_Token_At (I, "declare") then
                        Push_Anonymous_Block_Name (Anonymous_Declare_Name_At (I));
                     else
                        Push_Anonymous_Block_Name (Anonymous_Accept_Name_At (I));
                     end if;
                  elsif Tail_Nesting = 0
                    and then Tail_Token_At (I, "record")
                    and then not Previous_Token_Is_End (I)
                  then
                     Record_Nesting := Record_Nesting + 1;
                  elsif Tail_Nesting = 0
                    and then Has_Nested_Compact_Scope_Opener (I)
                  then
                     Compact_Scope_Nesting := Compact_Scope_Nesting + 1;
                     if Compact_Scope_Nesting <= Max_Compact_Callable_Nesting then
                        Compact_Scope_Begin_Seen (Compact_Scope_Nesting) := False;
                     end if;
                     Push_Compact_Scope_Name (Compact_Package_Name_At (I));
                  elsif Tail_Nesting = 0
                    and then Has_Nested_Compact_Callable_Body_Opener (I)
                  then
                     if Owner_Is_Callable
                       and then Callable_Body_Nesting = 0
                       and then Concurrent_Scope_Nesting = 0
                       and then Compact_Scope_Nesting = 0
                     then
                        Emit_Local_Compact_Callable (I);
                     end if;

                     Callable_Body_Nesting := Callable_Body_Nesting + 1;
                     Push_Compact_Callable_Name (Compact_Callable_Name_At (I));
                  elsif Tail_Nesting = 0
                    and then Has_Nested_Compact_Concurrent_Scope_Opener (I)
                  then
                     Concurrent_Scope_Nesting := Concurrent_Scope_Nesting + 1;
                     if Concurrent_Scope_Nesting <= Max_Compact_Callable_Nesting then
                        Concurrent_Scope_Begin_Seen (Concurrent_Scope_Nesting) := False;
                     end if;
                     Push_Compact_Concurrent_Name (Compact_Concurrent_Name_At (I));
                  elsif Tail_Line (I) = ';'
                    and then Tail_Nesting = 0
                    and then Record_Nesting = 0
                    and then Compact_Scope_Nesting = 0
                    and then Callable_Body_Nesting = 0
                    and then Concurrent_Scope_Nesting = 0
                  then
                     Parse_Tail_Segment (Segment_Start, I);
                     Segment_Start := I + 1;
                  end if;
               end loop;

               if Segment_Start <= Tail_Line'Last then
                  Parse_Tail_Segment (Segment_Start, Tail_Line'Last);
               end if;
            end;
         end;
      end Parse_Compact_Scope_Tail;

      procedure Parse_Compact_Record_Tail (Owner : Symbol_Id) is
      begin
         Editor.Ada_Declaration_Parser.Compact_Record_Tail_Phase.Parse_Compact_Record_Tail
           (Analysis, Raw_Line, Line_Number, Depth, Owner,
            Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase.Mark_Declaration_Form_Metadata'Access);
      end Parse_Compact_Record_Tail;

      procedure Parse_Record_Opener_Component_Tail (Owner : Symbol_Id) is
         Code         : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
         Lower_Code   : constant String := Lower (Code);
         Record_Start : Natural := 0;
      begin
         for I in Lower_Code'Range loop
            if Tail_Analysis_Helpers.Tail_Token_At (Lower_Code, I, "record") then
               Record_Start := I;
               exit;
            end if;
         end loop;

         if Record_Start = 0 or else Record_Start + 6 > Raw_Line'Last then
            return;
         end if;

         declare
            Tail_Line : String := Raw_Line;
         begin
            for I in Tail_Line'First .. Record_Start + 5 loop
               Tail_Line (I) := ' ';
            end loop;

            if Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line))'Length /= 0 then
               Declaration_Collectors.Add_Record_Component_Names
                 (Analysis, Tail_Line, Line_Number,
                  Natural'Min (Depth + 1, Max_Scope_Nesting), Owner,
                  Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase.Mark_Declaration_Form_Metadata'Access);
            end if;
         end;
      end Parse_Record_Opener_Component_Tail;

      function Strip_Leading_Statement_Labels (Text : String) return String
        renames Tail_Analysis_Helpers.Strip_Leading_Statement_Labels;

      function Strip_Leading_Named_Statement_Prefix (Text : String) return String
        renames Tail_Analysis_Helpers.Strip_Leading_Named_Statement_Prefix;

      procedure Mark_Statement_Awareness is
      begin
         Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker.Statement_Awareness.Mark_Statement_Awareness
           (Analysis, Lower_Line, Trimmed, In_Record);
      end Mark_Statement_Awareness;

   begin
      Mark_Source_Awareness (Analysis, Raw_Line);

      if Trimmed'Length = 0 then
         if Pending_Enumeration then
            Add_Enumeration_Literals_Continuation
              (Analysis, Raw_Line, Line_Number, Depth + 1,
               (if Pending_Enumeration_Owner /= No_Symbol then
                   Pending_Enumeration_Owner
                else
                   Current_Parent));
            if Ada.Strings.Fixed.Index (Lower (Raw_Line), ")") /= 0 then
               Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                 .Clear_Pending_Enumeration (Executable_Binding);
            end if;
         end if;
         return;
      end if;

      Mark_Statement_Awareness;

      if Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
           .Handle_Pending_Aspect_Line
             (Analysis, Source_Recovery, Raw_Line, Lower_Line, Line_Number)
      then
         return;
      end if;

      Mark_Context_Clause_Awareness
        (Analysis, Raw_Line, Line_Number,
         Scope_Id (Natural (Current_Parent)));

      if In_Record
        and then Starts_With_Word (Lower_Line, "case")
        and then Has_Token (Lower_Line, "is")
      then
         --  Variant parts are record-shape metadata owned by the enclosing
         --  record type.  The discriminant choice expressions and branch
         --  labels are not learned as standalone declarations here.
         Editor.Ada_Language_Model.Mark_Symbol_Variant_Record_Metadata
           (Analysis, Current_Parent);
         return;
      end if;

      Representation_Metadata.Mark_Representation_Clause_Target (Analysis, Raw_Line);
      Mark_Pragma_Target
        (Analysis, Raw_Line,
         Current_Parent);

      declare
         Code        : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
         Private_End : Natural := 0;
      begin
         for I in Code'Range loop
            if Code (I) = ';' then
               Private_End := I;
               exit;
            end if;
         end loop;

         if Private_End /= 0
           and then Private_End > Code'First
           and then Lower (Trim (Code (Code'First .. Private_End - 1))) = "private"
           and then Private_End < Raw_Line'Last
         then
            declare
               Tail_Line : String := Raw_Line;
            begin
               for I in Tail_Line'First .. Private_End loop
                  Tail_Line (I) := ' ';
               end loop;

               if Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line))'Length /= 0 then
                  --  Compact/generated Ada may put a package private-section
                  --  marker and the first private declaration on the same
                  --  physical line.  Mark the current scope private first,
                  --  then reparse the tail with absolute source columns
                  --  preserved by blanking the consumed prefix.
                  Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
                    .Mark_Current_Private (Scope_State);
                  declare
                     Segment_Start : Natural := Private_End + 1;
                     Nesting       : Natural := 0;

                     procedure Parse_Private_Segment (First, Last : Natural) is
                        Segment_Line : String := (Raw_Line'Range => ' ');
                     begin
                        if First > Last then
                           return;
                        end if;
                        Segment_Line (First .. Last) := Raw_Line (First .. Last);
                        if Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Segment_Line))'Length = 0 then
                           return;
                        end if;
                        Parse_Line (Analysis, Segment_Line, Line_Number, Context);
                     end Parse_Private_Segment;
                  begin
                     for I in Segment_Start .. Code'Last loop
                        if Code (I) = '(' then
                           Nesting := Nesting + 1;
                        elsif Code (I) = ')' then
                           if Nesting > 0 then
                              Nesting := Nesting - 1;
                           end if;
                        elsif Code (I) = ';' and then Nesting = 0 then
                           Parse_Private_Segment (Segment_Start, I);
                           Segment_Start := I + 1;
                        end if;
                     end loop;

                     if Segment_Start <= Raw_Line'Last then
                        Parse_Private_Segment (Segment_Start, Raw_Line'Last);
                     end if;
                  end;
                  return;
               end if;
            end;
         end if;
      end;

      if Lower_Line = "private" or else Lower_Line = "private;" then
         Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
           .Mark_Current_Private (Scope_State);
         return;
      end if;

      if Starts_With (Lower_Line, "end record") then
         --  Representation clauses use "for T use record ... end record;"
         --  without opening a language-model scope.  Only close a parser
         --  record scope when the parser is actually inside a record type.
         Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
           .Close_Record_Scope (Scope_State);
         Editor.Ada_Declaration_Parser.Parse_Line_Pending_Phase
           .Clear_After_Scope_Close (Context);
         return;
      end if;

      if Is_Scope_End (Lower_Line) then
         Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
           .Leave_Scope (Scope_State);
         Editor.Ada_Declaration_Parser.Parse_Line_Pending_Phase
           .Clear_After_Scope_Close (Context);
         return;
      end if;

      if Pending_Array_Target_Owner /= No_Symbol then
         declare
            Target : constant String := Array_Target_From_Line (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Pending_Array_Target_Owner, Target);
            end if;
         end;

         Pending_Array_Target_Owner := No_Symbol;
         return;
      end if;

      if Pending_Access_Target_Owner /= No_Symbol then
         declare
            Target  : constant String := Access_Target_From_Line_Start (Raw_Line);
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Pending_Access_Target_Owner, Target);
               if Pending_Access_Subprogram_Profile_Owner = Pending_Access_Target_Owner then
                  Pending_Access_Subprogram_Profile_Owner := No_Symbol;
               end if;
               Pending_Access_Target_Owner := No_Symbol;
               return;
            elsif Profile'Length /= 0
              and then Pending_Access_Subprogram_Profile_Owner = Pending_Access_Target_Owner
            then
               Set_Symbol_Profile (Analysis, Pending_Access_Target_Owner, Profile);
               Mark_Symbol_Access_Subprogram_Metadata
                 (Analysis, Pending_Access_Target_Owner);
               Pending_Access_Subprogram_Profile_Owner := No_Symbol;
               Pending_Access_Target_Owner := No_Symbol;
               return;
            else
               Pending_Access_Target_Owner := No_Symbol;
            end if;
         end;
      end if;

      if Pending_Access_Subprogram_Profile_Owner /= No_Symbol then
         declare
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
         begin
            if Profile'Length /= 0 then
               Set_Symbol_Profile
                 (Analysis, Pending_Access_Subprogram_Profile_Owner, Profile);
               Mark_Symbol_Access_Subprogram_Metadata
                 (Analysis, Pending_Access_Subprogram_Profile_Owner);
               Pending_Access_Subprogram_Profile_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Access_Subprogram_Profile_Owner := No_Symbol;
               return;
            else
               --  Split access-to-subprogram type declarations may put the
               --  callable profile on a continuation line:
               --     type Callback is access
               --        procedure (Item : Element);
               --  Keep those lines as type metadata so they do not become
               --  false declarations in the enclosing scope.
               return;
            end if;
         end;
      end if;

      if Pending_Return_Access_Target_Owner /= No_Symbol then
         declare
            Target  : constant String := Access_Target_From_Line_Start (Raw_Line);
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
            Owner   : constant Symbol_Id := Pending_Return_Access_Target_Owner;

            procedure Clear_Pending_Profile_For_Owner is
            begin
               if Pending_Profile_Owner = Owner then
                  Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase
                    .Clear_Pending_Profile (Profile_State);
               end if;
            end Clear_Pending_Profile_For_Owner;
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target
                 (Analysis, Owner, Target);
               if Pending_Return_Target_Owner = Owner then
                  Pending_Return_Target_Owner := No_Symbol;
               end if;
               Clear_Pending_Profile_For_Owner;
               if Pending_Body_Owner = Owner
                 and then Has_Code_Char (Lower_Line, ';')
               then
                  Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                    .Clear_Pending_Body (Executable_Binding);
               end if;
               Pending_Return_Access_Target_Owner := No_Symbol;
               return;
            elsif Profile'Length /= 0 then
               Set_Symbol_Profile
                 (Analysis, Owner, Profile);
               if Pending_Return_Target_Owner = Owner then
                  Pending_Return_Target_Owner := No_Symbol;
               end if;
               Clear_Pending_Profile_For_Owner;
               if Pending_Body_Owner = Owner
                 and then Has_Code_Char (Lower_Line, ';')
               then
                  Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                    .Clear_Pending_Body (Executable_Binding);
               end if;
               Pending_Return_Access_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               if Pending_Return_Target_Owner = Owner then
                  Pending_Return_Target_Owner := No_Symbol;
               end if;
               Clear_Pending_Profile_For_Owner;
               if Pending_Body_Owner = Owner then
                  Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                    .Clear_Pending_Body (Executable_Binding);
               end if;
               Pending_Return_Access_Target_Owner := No_Symbol;
               return;
            else
               --  Split anonymous access result declarations may put access
               --  qualifiers on one continuation line and either a designated
               --  subtype or callable profile on a later line:
               --     function Ref return access
               --        all Root'Class;
               --     function Handler return access
               --        procedure (Item : Element);
               --  Keep those lines as callable result metadata only.
               return;
            end if;
         end;
      end if;

      if Pending_Return_Target_Owner /= No_Symbol and then not Pending_Profile then
         declare
            Target : constant String := Return_Target_From_Line_Start (Raw_Line);
            Owner  : constant Symbol_Id := Pending_Return_Target_Owner;
         begin
            if Ada.Strings.Fixed.Index (Lower_Line, "return") /= 0
              and then Has_Token (Lower_Line, "access")
              and then not Has_Code_Char (Lower_Line, ';')
            then
               Pending_Return_Access_Target_Owner := Owner;
               return;
            elsif Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Owner, Target);
               Pending_Return_Target_Owner := No_Symbol;
               if Has_Code_Char (Lower_Line, ';') then
                  return;
               end if;
            elsif Has_Code_Char (Lower_Line, ';') or else Has_Token (Lower_Line, "is") then
               Pending_Return_Target_Owner := No_Symbol;
            else
               --  Keep waiting across harmless split return-subtype
               --  continuations, but do not treat those lines as separate
               --  declarations in the enclosing scope.
               return;
            end if;
         end;
      end if;

      if Pending_Subtype_Target_Owner /= No_Symbol then
         declare
            Target : constant String := Subtype_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Pending_Subtype_Target_Owner, Target);
               Pending_Subtype_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Subtype_Target_Owner := No_Symbol;
               return;
            else
               --  Split subtype declarations can put the subtype mark on a
               --  continuation line before range/aspect/default metadata:
               --     subtype Index is
               --        Positive range 1 .. 10;
               --  Keep those continuation lines as subtype metadata rather
               --  than parsing them as declarations in the enclosing scope.
               return;
            end if;
         end;
      end if;

      if Pending_Declaration_Target_Owner /= No_Symbol then
         declare
            Target : constant String := Declaration_Target_From_Line_Start (Raw_Line);
            Owner  : constant Symbol_Id := Pending_Declaration_Target_Owner;

            procedure Clear_Pending_Profile_For_Owner is
            begin
               if Pending_Profile_Owner = Owner then
                  Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase
                    .Clear_Pending_Profile (Profile_State);
               end if;
               if Pending_Body_Owner = Owner then
                  Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                    .Clear_Pending_Body (Executable_Binding);
               end if;
            end Clear_Pending_Profile_For_Owner;
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Owner, Target);
               Clear_Pending_Profile_For_Owner;
               Pending_Declaration_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Clear_Pending_Profile_For_Owner;
               Pending_Declaration_Target_Owner := No_Symbol;
               return;
            else
               --  Split renames/instantiations may put the renamed or
               --  generic unit name on a continuation line:
               --     package IO is new
               --        Ada.Text_IO.Integer_IO;
               --  Keep the continuation as declaration metadata so it does
               --  not become a false package-level declaration.
               return;
            end if;
         end;
      end if;

      if Pending_Generic_Formal_Subprogram_Target_Owner /= No_Symbol then
         declare
            Target : constant String :=
              Generic_Formal_Subprogram_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target
                 (Analysis, Pending_Generic_Formal_Subprogram_Target_Owner, Target);
               Pending_Generic_Formal_Subprogram_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Generic_Formal_Subprogram_Target_Owner := No_Symbol;
               return;
            else
               --  Split generic formal subprogram defaults may place the
               --  default callable name after a later "is" line.  Keep
               --  those continuation lines as formal metadata so they do not
               --  become ordinary declarations.
               return;
            end if;
         end;
      end if;

      if Pending_Generic_Formal_Package_Target_Owner /= No_Symbol then
         declare
            Target : constant String :=
              Generic_Formal_Package_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target
                 (Analysis, Pending_Generic_Formal_Package_Target_Owner, Target);
               Mark_Symbol_Instantiation
                 (Analysis, Pending_Generic_Formal_Package_Target_Owner);
               Pending_Generic_Formal_Package_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Generic_Formal_Package_Target_Owner := No_Symbol;
               return;
            else
               --  Split generic formal package declarations can put the
               --  "is new" phrase or the instantiated unit on a later line:
               --     with package Maps is
               --        new Ada.Containers.Ordered_Maps;
               --  Keep those lines as generic-formal metadata so they do not
               --  become false package-level declarations.
               return;
            end if;
         end;
      end if;

      if Pending_Object_Array_Target_Count > 0 then
         declare
            Target : constant String := Array_Target_From_Line (Raw_Line);
         begin
            if Target'Length /= 0 then
               for I in 1 .. Pending_Object_Array_Target_Count loop
                  Set_Symbol_Target
                    (Analysis, Pending_Object_Array_Target_Owners (I), Target);
               end loop;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Array_Targets (Declaration_Targets);
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Array_Targets (Declaration_Targets);
               return;
            else
               --  Split anonymous array object declarations may put the
               --  index constraint on one continuation line and the element
               --  subtype after "of" on a later line.  Treat those lines as
               --  declaration metadata until the target is found or the
               --  declaration terminates.
               return;
            end if;
         end;
      end if;

      if Pending_Object_Access_Target_Count > 0 then
         declare
            Target  : constant String := Access_Target_From_Line_Start (Raw_Line);
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
         begin
            if Target'Length /= 0 then
               for I in 1 .. Pending_Object_Access_Target_Count loop
                  Set_Symbol_Target
                    (Analysis, Pending_Object_Access_Target_Owners (I), Target);
               end loop;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Access_Targets (Declaration_Targets);
               return;
            elsif Profile'Length /= 0 then
               for I in 1 .. Pending_Object_Access_Target_Count loop
                  Set_Symbol_Profile
                    (Analysis, Pending_Object_Access_Target_Owners (I), Profile);
               end loop;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Access_Targets (Declaration_Targets);
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Access_Targets (Declaration_Targets);
               return;
            else
               --  Split anonymous access object/subprogram declarations may
               --  place null/all/constant/designated-subtype qualifiers or a
               --  callable profile on a continuation line.  Keep those lines
               --  as declaration metadata so they do not create false
               --  package-level symbols.
               return;
            end if;
         end;
      end if;

      if Pending_Object_Access_Subprogram_Profile_Count > 0 then
         declare
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
         begin
            if Profile'Length /= 0 then
               for I in 1 .. Pending_Object_Access_Subprogram_Profile_Count loop
                  Set_Symbol_Profile
                    (Analysis,
                     Pending_Object_Access_Subprogram_Profile_Owners (I),
                     Profile);
                  Mark_Symbol_Access_Subprogram_Metadata
                    (Analysis,
                     Pending_Object_Access_Subprogram_Profile_Owners (I));
               end loop;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Access_Subprogram_Profiles
                   (Declaration_Targets);
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Access_Subprogram_Profiles
                   (Declaration_Targets);
               return;
            else
               --  Split anonymous access-to-subprogram object declarations
               --  can put the callable profile on a later continuation line:
               --     Handler : access
               --        procedure (Item : Element);
               --  Keep those lines as object-type metadata so profile
               --  parameters do not become package-level declarations.
               return;
            end if;
         end;
      end if;

      if Pending_Generic_Formal_Object_Target_Count > 0 then
         declare
            Target  : constant String := Object_Target_From_Line_Start (Raw_Line);
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
         begin
            if Profile'Length /= 0 then
               for I in 1 .. Pending_Generic_Formal_Object_Target_Count loop
                  Set_Symbol_Profile
                    (Analysis, Pending_Generic_Formal_Object_Target_Owners (I), Profile);
               end loop;
               Pending_Generic_Formal_Object_Target_Owners := (others => No_Symbol);
               Pending_Generic_Formal_Object_Target_Count := 0;
               return;
            elsif Target'Length /= 0 then
               for I in 1 .. Pending_Generic_Formal_Object_Target_Count loop
                  Set_Symbol_Target
                    (Analysis, Pending_Generic_Formal_Object_Target_Owners (I), Target);
               end loop;
               Pending_Generic_Formal_Object_Target_Owners := (others => No_Symbol);
               Pending_Generic_Formal_Object_Target_Count := 0;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Generic_Formal_Object_Target_Owners := (others => No_Symbol);
               Pending_Generic_Formal_Object_Target_Count := 0;
               return;
            else
               --  Split generic formal object declarations may put mode
               --  keywords, subtype marks, or anonymous access-to-subprogram
               --  profiles on later lines.  Keep those lines as
               --  formal-declaration metadata rather than learning them as
               --  ordinary package-level objects.
               return;
            end if;
         end;
      end if;

      if Pending_Interface_Target_Owner /= No_Symbol then
         declare
            Target : constant String := Interface_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Pending_Interface_Target_Owner, Target);
               Pending_Interface_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Interface_Target_Owner := No_Symbol;
               return;
            else
               --  Split interface declarations can put the parent interface
               --  after a trailing "and" on a continuation line:
               --     type Child is limited interface and
               --        Root;
               --  Treat that continuation as type metadata instead of a
               --  standalone declaration in the enclosing scope.
               return;
            end if;
         end;
      end if;

      if Pending_Derived_Target_Owner /= No_Symbol then
         declare
            Target : constant String := Derived_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Pending_Derived_Target_Owner, Target);
            end if;

            if Has_Token (Lower_Line, "record") then
               --  Split derived record extensions can place both the parent
               --  subtype and the record opener on the continuation line:
               --     type Child is new
               --        Parent with record
               --  Stamp the parent target and open the record scope from the
               --  same metadata line rather than learning it as a declaration.
               Set_Symbol_Kind (Analysis, Pending_Derived_Target_Owner, Symbol_Record_Type);
            Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
              .Open_Record_Scope (Scope_State, Pending_Derived_Target_Owner);
               Pending_Record_After_Is_Owner := No_Symbol;
               Pending_Derived_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Record_After_Is_Owner := No_Symbol;
               Pending_Derived_Target_Owner := No_Symbol;
               return;
            else
               --  Keep intermediate derived-type metadata lines from being
               --  interpreted as standalone declarations.
               Pending_Derived_Target_Owner := No_Symbol;
               return;
            end if;
         end;
      end if;

      if Pending_Record_After_Is_Owner /= No_Symbol then
         if Has_Token (Lower_Line, "record") then
            --  Handle Ada style split over the body opener:
            --     type Rec is
            --        record
            --  The first line has already emitted the type symbol; the
            --  record line upgrades it and opens the record scope so
            --  subsequent components are owned by the record type.
            Set_Symbol_Kind (Analysis, Pending_Record_After_Is_Owner, Symbol_Record_Type);
            Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
              .Open_Record_Scope (Scope_State, Pending_Record_After_Is_Owner);
            Pending_Record_After_Is_Owner := No_Symbol;
            return;
         else
            --  If the continuation is not a record opener, stop treating it
            --  as a split record header and let normal declaration parsing
            --  inspect the line.  This keeps incomplete/other type forms
            --  conservative rather than swallowing valid declarations.
            Pending_Record_After_Is_Owner := No_Symbol;
         end if;
      end if;

      if Pending_Type_Header_Owner /= No_Symbol then
         if Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0
           and then Ada.Strings.Fixed.Index (Lower_Line, "(") /= 0
         then
            Add_Discriminant_Names
              (Analysis, Raw_Line, Line_Number, Depth + 1,
               Pending_Type_Header_Owner);
            Pending_Discriminants := Ada.Strings.Fixed.Index (Lower_Line, ")") = 0;
            Pending_Discriminant_Owner := Pending_Type_Header_Owner;
         elsif Pending_Discriminants
           and then Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0
         then
            Add_Discriminant_Names
              (Analysis, Raw_Line, Line_Number, Depth + 1,
               Pending_Type_Header_Owner);
         end if;

         if Has_Token (Lower_Line, "record") then
            Set_Symbol_Kind (Analysis, Pending_Type_Header_Owner, Symbol_Record_Type);
            Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
              .Open_Record_Scope (Scope_State, Pending_Type_Header_Owner);
            Pending_Type_Header_Owner := No_Symbol;
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
            return;
         elsif Has_Code_Char (Lower_Line, ';') and then not Pending_Discriminants then
            Pending_Type_Header_Owner := No_Symbol;
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
         elsif Ada.Strings.Fixed.Index (Lower_Line, ")") /= 0 then
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
         end if;

         return;
      end if;

      if Pending_Concurrent_Header_Owner /= No_Symbol then
         if Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0 then
            Add_Discriminant_Names
              (Analysis, Raw_Line, Line_Number, Depth + 1,
               Pending_Concurrent_Header_Owner);
            Pending_Discriminants := Ada.Strings.Fixed.Index (Lower_Line, ")") = 0;
            Pending_Discriminant_Owner := Pending_Concurrent_Header_Owner;
         end if;

         if Has_Token (Lower_Line, "is")
           and then not Has_Code_Char (Lower_Line, ';')
         then
            Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
              .Enter_Scope (Scope_State, Pending_Concurrent_Header_Owner);
            Pending_Concurrent_Header_Owner := No_Symbol;
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
            return;
         elsif Has_Code_Char (Lower_Line, ';') and then not Pending_Discriminants then
            Pending_Concurrent_Header_Owner := No_Symbol;
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
         elsif Ada.Strings.Fixed.Index (Lower_Line, ")") /= 0 then
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
         end if;

         return;
      end if;

      if Pending_Discriminants then
         if Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0 then
            Add_Discriminant_Names (Analysis, Raw_Line, Line_Number, Depth + 1,
                                    (if Pending_Discriminant_Owner /= No_Symbol then
                                        Pending_Discriminant_Owner
                                      else
                                        Current_Parent));
         end if;
         if Ada.Strings.Fixed.Index (Lower_Line, ")") /= 0 then
            if Has_Token (Lower_Line, "record") then
               if Pending_Discriminant_Owner /= No_Symbol then
                  Set_Symbol_Kind
                    (Analysis, Pending_Discriminant_Owner, Symbol_Record_Type);
               end if;
               if Pending_Discriminant_Owner /= No_Symbol then
                  Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
                    .Open_Record_Scope (Scope_State, Pending_Discriminant_Owner);
               else
                  Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
                    .Set_In_Record (Scope_State, True);
               end if;
            end if;
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
         end if;
         return;
      end if;

      if Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
        .Handle_Executable_Continuation
          (Analysis, Raw_Line, Lower_Line, Line_Number, Depth,
           Current_Parent, Starts_With_Declaration_Or_Metadata,
           Declaration_Targets, Executable_Binding, Scope_State)
      then
         return;
      end if;

      if Pending_Profile then
         Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase
           .Handle_Pending_Profile_Continuation
             (Analysis, Raw_Line, Lower_Line, Line_Number, Depth,
              Profile_State, Declaration_Targets, Executable_Binding,
              Scope_State);
         return;
      end if;

      if In_Record then
         if Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0 then
            --  Record components may split their default expression or
            --  aspect clause away from the subtype line:
            --     Child : Root'Class
            --        := Default;
            --  Learn the component from the owning declaration line and
            --  leave the continuation as metadata-only.
            Add_Record_Component_Names
              (Analysis, Raw_Line, Line_Number, Depth,
               Current_Parent);
            return;
         end if;
      end if;

      if Starts_With_Word (Lower_Line, "generic") then
         Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
           .Begin_Generic (Declaration_Targets);

         declare
            function Parse_Generic_Segment
              (First : Natural;
               Last  : Natural) return Boolean
            is
               Segment_Line : String := (Raw_Line'Range => ' ');
            begin
               if First > Last then
                  return False;
               end if;

               Segment_Line (First .. Last) := Raw_Line (First .. Last);
               if Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Segment_Line))'Length = 0 then
                  return False;
               end if;

               Parse_Line (Analysis, Segment_Line, Line_Number, Context);
               return True;
            end Parse_Generic_Segment;

            procedure Parse_Generic_Tail is new
              Editor.Ada_Declaration_Parser.Generic_Tail_Phase.Parse_Same_Line_Generic_Tail
                (Parse_Segment => Parse_Generic_Segment);
         begin
            Parse_Generic_Tail (Raw_Line);
         end;

         return;
      end if;

      if Starts_With_Word (Lower_Line, "separate") then
         declare
            Code  : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
            Close : Natural := 0;
         begin
            for I in Code'Range loop
               if Code (I) = ')' then
                  Close := I;
                  exit;
               end if;
            end loop;

            if Close /= 0 and then Close < Raw_Line'Last then
               declare
                  Tail_Line : String := Raw_Line;
               begin
                  for I in Tail_Line'First .. Close loop
                     Tail_Line (I) := ' ';
                  end loop;

                  declare
                     Tail_Code : constant String :=
                       Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line));
                  begin
                     if Tail_Code'Length /= 0 then
                        --  Compact/generated Ada can put the separate parent
                        --  marker and the following body declaration on the
                        --  same physical line.  Preserve absolute source
                        --  columns by blanking the consumed prefix, then parse
                        --  the body with Pending_Separate_Target set.
                        Editor.Ada_Declaration_Parser
                          .Parse_Line_Source_Recovery_Phase
                          .Set_Pending_Separate_Target
                            (Source_Recovery, Separate_Parent_Name (Trimmed));
                        Parse_Line (Analysis, Tail_Line, Line_Number, Context);
                        return;
                     end if;
                  end;
               end;
            end if;
         end;
      end if;

      if Starts_With_Word (Lower_Line, "separate")
        and then Ada.Strings.Fixed.Index (Lower_Line, ")") = Lower_Line'Last
      then
         Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
           .Set_Pending_Separate_Target
             (Source_Recovery, Separate_Parent_Name (Trimmed));
         return;
      end if;

      Flags.Is_Private := Starts_With (Lower_Line, "private ")
        or else Current_Private
        or else (Starts_With_Word (Decl_Lower, "type")
                 and then Has_Token (Decl_Lower, "private"));
      Flags.Is_Abstract := Starts_With (Lower_Line, "abstract ") or else Ada.Strings.Fixed.Index (Lower_Line, " abstract ") /= 0;
      Flags.Is_Overriding := Starts_With (Lower_Line, "overriding ");
      Flags.Is_Not_Overriding := Starts_With (Lower_Line, "not overriding ");
      Flags.Is_Separate := Starts_With_Word (Lower_Line, "separate")
        or else Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
          .Has_Pending_Separate_Target (Source_Recovery)
        or else (Has_Token (Lower_Line, "is")
                 and then Has_Token (Lower_Line, "separate"));
      Flags.Has_Aspect_Specification := Metadata_Helpers.Has_Aspect_Specification (Trimmed);
      Flags.Has_Null_Exclusion := Has_Null_Exclusion (Trimmed);
      Flags.Has_Aliased_Metadata := Has_Aliased_Metadata (Trimmed);
      Flags.Has_Deferred_Constant_Metadata := Has_Deferred_Constant_Metadata (Trimmed);
      Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase.Mark_Declaration_Form_Metadata (Flags, Trimmed);
      if Starts_With_Word (Lower_Line, "separate") then
         Set_Target (Separate_Parent_Name (Trimmed));
      elsif Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
        .Has_Pending_Separate_Target (Source_Recovery)
      then
         Set_Target
           (Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
              .Consume_Pending_Separate_Target (Source_Recovery));
      end if;
      Flags.Is_Rename := Has_Token (Lower_Line, "renames");
      --  Access-to-subprogram type profiles are type metadata, not
      --  discriminant parts or callable declarations; the type branches
      --  below explicitly exclude access types from discriminant learning.
      --  Instantiation is declaration-family specific.  A derived type such
      --  as "type T is new Parent" contains the Ada keyword "new" but is
      --  not a generic instantiation; set this flag only in package,
      --  procedure, function, and formal-package branches that actually
      --  represent instantiations.
      Flags.Is_Instantiation := False;

      if Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
        .Handle_Same_Line_Declaration_Groups
          (Analysis, Raw_Line, Decl, Decl_Lower, Line_Number, Depth,
           Current_Parent, Flags.Is_Private, Pending_Generic, Profile_State)
      then
         return;
      end if;

      if Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
        .Recognize_Declaration_Line
          (Analysis, Raw_Line, Raw_Decl, Decl, Decl_Lower, Line_Number,
           Depth, Current_Parent, Scope_State, Declaration_Targets,
           Phase_State)
      then
         return;
      end if;

      if Kind /= Symbol_Unknown then
         if (Kind = Symbol_Procedure
             or else Kind = Symbol_Function
             or else Kind = Symbol_Operator_Function)
           and then Has_Token (Decl_Lower, "is")
           and then not Has_Code_Char (Decl_Lower, ';')
           and then not Flags.Is_Instantiation
           and then not Flags.Is_Rename
           and then not Flags.Is_Separate
         then
            --  retain callable body/spec metadata so indexed
            --  Outline navigation can safely pair subprogram declarations
            --  with their bodies instead of treating same-name callables as
            --  indistinguishable overload candidates.
            Flags.Is_Body := True;
         end if;

         if Name_Len > 0
           and then Is_Invalid_Compact_Owner_Name (Current_Name)
         then
            --  keep malformed/in-progress declarations from
            --  learning Ada reserved words as real language-model symbols in
            --  the fallback declaration path as well as in compact tail
            --  splitters.  If the malformed declaration was the generic unit
            --  following a same-line ``generic;`` marker, consume that marker
            --  so later independent declarations are not misclassified as the
            --  generic unit.
            if Pending_Generic
              and then Kind in Symbol_Package | Symbol_Package_Body |
                Symbol_Procedure | Symbol_Function | Symbol_Operator_Function
            then
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Consume_Generic_Unit (Declaration_Targets);
            end if;
            return;
         end if;

         declare
            New_Id : constant Symbol_Id := Emit;
         begin
            Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
              .Add_Trailing_Bare_Aspect
                (Analysis, New_Id, Raw_Line, Line_Number);

            if New_Id /= No_Symbol
              and then Kind = Symbol_Generic_Formal_Type
              and then Name_Len > 0
            then
               Add_Generic_Formal_Type_Metadata
                 (Analysis, New_Id, Current_Name,
                  Generic_Formal_Type_Family_From_Line (Decl),
                  Target_Type_Text =>
                    Current_Target,
                  Profile_Text =>
                    Current_Profile,
                  Has_Private => Has_Token (Decl_Lower, "private"),
                  Has_Limited => Flags.Has_Limited_Metadata,
                  Has_Tagged => Flags.Has_Tagged_Metadata,
                  Has_Abstract => Flags.Is_Abstract,
                  Has_Synchronized => Flags.Has_Synchronized_Metadata,
                  Has_Interface => Flags.Has_Interface_Metadata,
                  Has_Box => Ada.Strings.Fixed.Index (Decl_Lower, "<>") /= 0,
                  Has_Discriminant_Part =>
                    Ada.Strings.Fixed.Index (Decl_Lower, "(") /= 0
                    and then Ada.Strings.Fixed.Index (Decl_Lower, ":") /= 0,
                  Source_Span => (Line_Number, First_Non_Blank_Column (Raw_Line), Line_Number,
                            Positive'Max (First_Non_Blank_Column (Raw_Line),
                                          First_Non_Blank_Column (Raw_Line) + Name_Len - 1)));
            end if;
            if New_Id /= No_Symbol
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  The next line may be a split aspect specification owned by
               --  this declaration.  Non-aspect continuation lines clear this
               --  pending owner before normal parsing, so incomplete type,
               --  record, profile, and body continuations remain conservative.
               Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
                 .Set_Pending_Aspect_Owner (Source_Recovery, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Package
                        or else Kind = Symbol_Package_Body
                        or else Kind = Symbol_Procedure
                        or else Kind = Symbol_Function
                        or else Kind = Symbol_Operator_Function
                        or else Kind = Symbol_Task
                        or else Kind = Symbol_Protected)
              and then Has_Token (Decl_Lower, "is")
              and then Has_Code_Char (Decl_Lower, ';')
              and then not Flags.Is_Instantiation
              and then not Flags.Is_Rename
              and then not Flags.Is_Separate
            then
               Parse_Compact_Scope_Tail (New_Id);
            end if;

            if Kind = Symbol_Record_Type
              and then Has_Token (Lower_Line, "record")
            then
               declare
                  Record_Id : Symbol_Id := New_Id;
               begin
                  if Record_Id = No_Symbol and then Name_Len > 0 then
                     Record_Id :=
                       Editor.Ada_Symbol_Resolver.First_Match_In_Scope
                         (Analysis, Current_Name,
                          Current_Parent);
                  end if;

                  if Record_Id /= No_Symbol then
                     if Ada.Strings.Fixed.Index (Lower_Line, "end record") = 0 then
                        Parse_Record_Opener_Component_Tail (Record_Id);
                     end if;
                     Parse_Compact_Record_Tail (Record_Id);
                  end if;
               end;
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Type
                        or else Kind = Symbol_Generic_Formal_Type)
              and then Ada.Strings.Fixed.Index (Decl_Lower, "(") = 0
              and then not Has_Token (Decl_Lower, "is")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Type_Header (Declaration_Targets, New_Id);
            elsif New_Id /= No_Symbol
              and then Kind = Symbol_Type
              and then Has_Token (Decl_Lower, "is")
              and then not Has_Token (Decl_Lower, "record")
              and then not Has_Token (Decl_Lower, "private")
              and then not Has_Token (Decl_Lower, "access")
              and then not Has_Token (Decl_Lower, "array")
              and then not Has_Token (Decl_Lower, "range")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support:
               --     type Rec is
               --        record
               --  without opening a scope until the record opener is seen.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Record_After_Is
                   (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Type
                        or else Kind = Symbol_Generic_Formal_Type)
              and then Has_Token (Decl_Lower, "new")
              and then Target_Len = 0
              and then not Has_Token (Decl_Lower, "access")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split derived type/formal type declarations:
               --     type Child is new
               --        Parent with private;
               --  The type symbol comes from the header; the continuation
               --  line supplies the parent subtype target metadata.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Derived_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then Kind = Symbol_Subtype
              and then Target_Len = 0
              and then Has_Token (Decl_Lower, "is")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split subtype declarations:
               --     subtype Index is
               --        Positive range 1 .. 10;
               --  The subtype symbol is emitted from the header line, while
               --  the following metadata line supplies the target subtype.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Subtype_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Type
                        or else Kind = Symbol_Generic_Formal_Type)
              and then Has_Token (Decl_Lower, "interface")
              and then Has_Token (Decl_Lower, "and")
              and then Target_Len = 0
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split interface parent declarations:
               --     type Child is limited interface and
               --        Root;
               --  The header owns the type symbol; the continuation line
               --  supplies the parent interface target metadata.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Interface_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Type
                        or else Kind = Symbol_Generic_Formal_Type)
              and then Has_Token (Decl_Lower, "array")
              and then Target_Len = 0
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split array type declarations:
               --     type Table is array
               --        (Positive range <>) of Element;
               --  The first line owns the type symbol; the continuation line
               --  supplies the component subtype target metadata.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Array_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Type
                        or else Kind = Symbol_Generic_Formal_Type)
              and then Has_Token (Decl_Lower, "access")
              and then Target_Len = 0
              and then Profile_Len = 0
              and then not Has_Token (Decl_Lower, "procedure")
              and then not Has_Token (Decl_Lower, "function")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split access-to-object and access-to-subprogram
               --  type declarations.  The continuation line determines
               --  whether to stamp a designated subtype target or a callable
               --  profile.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Access_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Function
                        or else Kind = Symbol_Operator_Function
                        or else Kind = Symbol_Generic_Formal_Subprogram)
              and then Target_Len = 0
              and then Ada.Strings.Fixed.Index (Decl_Lower, " return ") /= 0
              and then Ada.Strings.Fixed.Index (Decl_Lower, " access") /= 0
              and then not Flags.Is_Rename
              and then not Flags.Is_Separate
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split anonymous access result subtypes/profiles:
               --     function Ref return access
               --        all Root'Class;
               --     function Handler return not null access
               --        procedure (Item : Element);
               --  The callable symbol is emitted from the header; the
               --  continuation supplies either the designated subtype target
               --  or callable result profile metadata.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Return_Access_Target
                   (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Function
                        or else Kind = Symbol_Operator_Function
                        or else Kind = Symbol_Generic_Formal_Subprogram)
              and then Target_Len = 0
              and then not Flags.Is_Rename
              and then not Flags.Is_Separate
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Split function result subtype metadata can appear after
               --  the declaration/profile line:
               --     function Make
               --        return Root'Class;
               --  Keep the callable owner pending so the following return
               --  line can update Target_Name without being parsed as a
               --  separate declaration.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Return_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then Target_Len = 0
              and then (Flags.Is_Rename or else Flags.Is_Instantiation)
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split rename/instantiation targets:
               --     package Maps is new
               --        Ada.Containers.Ordered_Maps;
               --     procedure Old renames
               --        New_Name;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Declaration_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then Kind = Symbol_Generic_Formal_Package
              and then Target_Len = 0
              and then not Flags.Is_Instantiation
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split generic formal package targets where the
               --  "new" token itself appears on the continuation line:
               --     with package Maps is
               --        new Ada.Containers.Ordered_Maps;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Generic_Formal_Package_Target
                   (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then Kind = Symbol_Generic_Formal_Subprogram
              and then Target_Len = 0
              and then Has_Token (Decl_Lower, "is")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split generic formal subprogram defaults:
               --     with procedure Visit (Item : Element) is
               --        Default_Visit;
               --  The formal subprogram owns the symbol; the continuation
               --  supplies the default callable target metadata.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Generic_Formal_Subprogram_Target
                   (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Procedure
                        or else Kind = Symbol_Function
                        or else Kind = Symbol_Operator_Function
                        or else Kind = Symbol_Generic_Formal_Subprogram
                        or else Kind = Symbol_Entry)
            then
               Add_Profile_Parameter_Names
                 (Analysis, Raw_Line, Line_Number, Depth + 1, New_Id,
                  Current_Name,
                  Pending_Profile_Access_Target_Owners,
                  Pending_Profile_Access_Target_Count);
               if Profile_Still_Open (Raw_Line, Current_Name) then
                  Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase
                    .Set_Pending_Profile (Profile_State, New_Id);
               end if;
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Task or else Kind = Symbol_Protected)
            then
               if Ada.Strings.Fixed.Index (Decl_Lower, "(") /= 0
                 and then Ada.Strings.Fixed.Index (Decl_Lower, ":") /= 0
               then
                  --  Ada task/protected types may have discriminant parts:
                  --     task type Worker (Id : Positive) is
                  --     protected type Cache (Size : Positive) is
                  --  Treat those names as discriminants owned by the concurrent
                  --  type symbol rather than as package-level objects.
                  Add_Discriminant_Names
                    (Analysis, Raw_Line, Line_Number, Depth + 1, New_Id);
               end if;

               if not Has_Token (Decl_Lower, "is")
                 and then not Has_Code_Char (Decl_Lower, ';')
               then
                  --  Split concurrent type headers can put either the whole
                  --  discriminant part or no discriminant part before the later
                  --  body-opening "is":
                  --     task type Worker (Id : Positive)
                  --     is
                  --  Keep the concurrent owner pending so entries/protected
                  --  operations after the later "is" are parented to the
                  --  task/protected type rather than the enclosing package.
                  Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                    .Set_Pending_Concurrent_Header
                      (Declaration_Targets, New_Id);
               end if;
            end if;

            if Pending_Discriminants and then Pending_Discriminant_Owner = No_Symbol then
                  Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                    .Set_Pending_Discriminants
                      (Declaration_Targets, New_Id);
               if Ada.Strings.Fixed.Index (Decl_Lower, ")") /= 0 then
                  Add_Discriminant_Names (Analysis, Raw_Line, Line_Number, Depth + 1,
                                          New_Id);
                  Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                    .Clear_Pending_Discriminants (Declaration_Targets);
               end if;
            elsif Kind = Symbol_Type
              and then Ada.Strings.Fixed.Index (Decl_Lower, "(") /= 0
              and then not Has_Token (Decl_Lower, "record")
              and then not Has_Token (Decl_Lower, "array")
              and then not Has_Token (Decl_Lower, "range")
              and then not Has_Token (Decl_Lower, "access")
            then
               Add_Enumeration_Literals (Analysis, Raw_Line, Line_Number, Depth + 1,
                                         New_Id);
               if Ada.Strings.Fixed.Index (Decl_Lower, "(") /= 0
                 and then Ada.Strings.Fixed.Index (Decl_Lower, ")") = 0
               then
                  Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                    .Set_Pending_Enumeration (Executable_Binding, New_Id);
               end if;
            end if;
            if Has_Token (Decl_Lower, "is") and then not Has_Code_Char (Decl_Lower, ';')
           and then not Flags.Is_Instantiation and then not Flags.Is_Rename
           and then Kind /= Symbol_Type and then Kind /= Symbol_Subtype
           and then Kind /= Symbol_Generic_Formal_Subprogram
         then
               Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
                 .Enter_Scope (Scope_State, New_Id);
            end if;
         end;
      end if;
   end Parse_Line;
