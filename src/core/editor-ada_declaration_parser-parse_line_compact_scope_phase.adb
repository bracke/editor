with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase;
with Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
with Editor.Ada_Declaration_Parser.Source_Awareness;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers;
with Editor.Ada_Syntax_Core;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Parse_Line_Compact_Scope_Phase is

   use Editor.Ada_Language_Model;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
   use Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
   use Editor.Ada_Declaration_Parser.Source_Awareness;
   use Editor.Ada_Declaration_Parser.Target_Helpers;
   use Editor.Text_Helpers;

   subtype Parse_Line_Context is
     Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Context;

   procedure Parse_Compact_Scope_Tail
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Owner       : Symbol_Id;
      Context     : in out Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Context)
   is
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


end Editor.Ada_Declaration_Parser.Parse_Line_Compact_Scope_Phase;
