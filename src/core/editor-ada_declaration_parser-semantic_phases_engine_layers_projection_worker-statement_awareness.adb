with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Same_Line_Declarations;
with Editor.Ada_Declaration_Parser.Same_Line_Emitters;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Source_Awareness;
with Editor.Ada_Declaration_Parser.Parse_Line_Phase_States;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Language_Model;

use Editor.Ada_Language_Model;
use Editor.Text_Helpers;
use Editor.Ada_Declaration_Parser.Lexical_Helpers;
use Editor.Ada_Declaration_Parser.Source_Awareness;
use Editor.Ada_Declaration_Parser.Metadata_Helpers;
use Editor.Ada_Declaration_Parser.Parse_Line_Phase_States;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker.Statement_Awareness is

   procedure Mark_Statement_Awareness
     (Analysis   : in out Analysis_Result;
      Lower_Line : String;
      Trimmed    : String;
      In_Record  : Boolean)
   is

      function Strip_Leading_Statement_Labels (Text : String) return String
        renames Tail_Analysis_Helpers.Strip_Leading_Statement_Labels;

      function Strip_Leading_Named_Statement_Prefix (Text : String) return String
        renames Tail_Analysis_Helpers.Strip_Leading_Named_Statement_Prefix;

      Statement_Line : constant String :=
        Strip_Leading_Named_Statement_Prefix
          (Strip_Leading_Statement_Labels (Lower_Line));
      Statement_Raw  : constant String :=
        Strip_Leading_Named_Statement_Prefix
          (Strip_Leading_Statement_Labels (Trimmed));

      function Has_Leading_Named_Statement return Boolean is
         Label_Stripped : constant String := Strip_Leading_Statement_Labels (Lower_Line);
         Normalized     : constant String := Strip_Leading_Named_Statement_Prefix (Label_Stripped);
      begin
         return Trim (Label_Stripped) /= Normalized;
      end Has_Leading_Named_Statement;

      function Leading_Statement_Label_Count (Text : String) return Natural
        renames Tail_Analysis_Helpers.Leading_Statement_Label_Count;


      procedure Mark_Leading_Statement_Labels is
         Count : constant Natural := Leading_Statement_Label_Count (Lower_Line);
      begin
         for I in 1 .. Count loop
            Mark_Statement_Kind (Analysis, Statement_Label);
         end loop;
      end Mark_Leading_Statement_Labels;

      function Looks_Like_Call_Statement (Line : String) return Boolean is
         Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
         Semi : constant Natural := Ada.Strings.Fixed.Index (Code, ";");
         I    : Natural := Code'First;
      begin
         if Semi = 0
           or else Lexical_Helpers.Is_Declaration_Or_Metadata_Line (Trim (Lower (Code)))
           or else Starts_With_Word (Trim (Lower (Code)), "exception")
           or else Starts_With_Word (Trim (Lower (Code)), "if")
           or else Starts_With_Word (Trim (Lower (Code)), "elsif")
           or else Starts_With_Word (Trim (Lower (Code)), "else")
           or else Starts_With_Word (Trim (Lower (Code)), "case")
           or else Starts_With_Word (Trim (Lower (Code)), "when")
           or else Starts_With_Word (Trim (Lower (Code)), "while")
           or else Starts_With_Word (Trim (Lower (Code)), "for")
           or else Starts_With_Word (Trim (Lower (Code)), "loop")
           or else Starts_With_Word (Trim (Lower (Code)), "declare")
           or else Starts_With_Word (Trim (Lower (Code)), "begin")
           or else Starts_With_Word (Trim (Lower (Code)), "end")
           or else Starts_With_Word (Trim (Lower (Code)), "select")
           or else Starts_With_Word (Trim (Lower (Code)), "or")
           or else Starts_With_Word (Trim (Lower (Code)), "then")
           or else Starts_With_Word (Trim (Lower (Code)), "accept")
           or else Starts_With_Word (Trim (Lower (Code)), "terminate")
           or else Starts_With_Word (Trim (Lower (Code)), "return")
           or else Starts_With_Word (Trim (Lower (Code)), "raise")
           or else Starts_With_Word (Trim (Lower (Code)), "null")
           or else Starts_With_Word (Trim (Lower (Code)), "exit")
           or else Starts_With_Word (Trim (Lower (Code)), "goto")
           or else Starts_With_Word (Trim (Lower (Code)), "delay")
           or else Starts_With_Word (Trim (Lower (Code)), "requeue")
           or else Starts_With_Word (Trim (Lower (Code)), "abort")
           or else Starts_With_Word (Trim (Lower (Code)), "pragma")
           or else Ada.Strings.Fixed.Index (Code, ":=") /= 0
         then
            return False;
         end if;

         while I <= Code'Last
           and then (Code (I) = ' ' or else Code (I) = Ada.Characters.Latin_1.HT)
         loop
            I := I + 1;
         end loop;

         if I > Code'Last then
            return False;
         end if;

         if not ((Code (I) >= 'A' and then Code (I) <= 'Z')
                 or else (Code (I) >= 'a' and then Code (I) <= 'z'))
         then
            return False;
         end if;

         for J in I .. Semi loop
            if Code (J) = ':' then
               return False;
            end if;
         end loop;

         return True;
      end Looks_Like_Call_Statement;

      function Looks_Like_Call_Statement return Boolean is
      begin
         return Looks_Like_Call_Statement (Statement_Raw);
      end Looks_Like_Call_Statement;


      function Looks_Like_Code_Statement return Boolean is
         Code       : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Statement_Raw);
         Semi       : constant Natural := Ada.Strings.Fixed.Index (Code, ";");
         Tick_Open  : constant Natural := Ada.Strings.Fixed.Index (Code, "'(");
         Open_Paren : constant Natural := Ada.Strings.Fixed.Index (Code, "(");
      begin
         --  Ada code statements are qualified expressions used as statements,
         --  for example a machine-code insertion form such as
         --     Instruction'(Opcode => 16#90#);
         --  They are syntactically statement forms rather than declarations.
         --  Keep this recognition conservative: require a qualified-expression
         --  apostrophe before the statement semicolon and an aggregate/call
         --  delimiter after it, while still rejecting declaration/metadata
         --  lines and assignments.
         return Semi /= 0
           and then Tick_Open /= 0
           and then Tick_Open < Semi
           and then Open_Paren /= 0
           and then Open_Paren < Semi
           and then not Lexical_Helpers.Is_Declaration_Or_Metadata_Line (Statement_Line)
           and then Ada.Strings.Fixed.Index (Code, ":=") = 0;
      end Looks_Like_Code_Statement;


      function Call_Has_Arguments return Boolean is
         Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Statement_Raw);
         Semi : constant Natural := Ada.Strings.Fixed.Index (Code, ";");
         Open : constant Natural := Ada.Strings.Fixed.Index (Code, "(");
      begin
         return Semi /= 0 and then Open /= 0 and then Open < Semi;
      end Call_Has_Arguments;

      function Call_Has_Named_Association return Boolean is
         Code  : constant String := Normalized_Line (Statement_Raw);
         Semi  : constant Natural := Ada.Strings.Fixed.Index (Code, ";");
         Arrow : constant Natural := Ada.Strings.Fixed.Index (Code, "=>");
         Open  : constant Natural := Ada.Strings.Fixed.Index (Code, "(");
      begin
         return Semi /= 0
           and then Open /= 0
           and then Arrow /= 0
           and then Open < Arrow
           and then Arrow < Semi;
      end Call_Has_Named_Association;

      function Call_Has_Selected_Name return Boolean is
         Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Statement_Raw);
         Semi : constant Natural := Ada.Strings.Fixed.Index (Code, ";");
         Dot  : constant Natural := Ada.Strings.Fixed.Index (Code, ".");
      begin
         --  Selected-name procedure/entry calls such as ``Pkg.Flush;`` and
         --  ``Obj.Operation (X);`` are ordinary call statements, but retaining
         --  the selected-name shape gives the language model a more precise
         --  statement fingerprint without resolving the target here.  Code
         --  statements are handled before call statements and therefore never
         --  reach this predicate.
         return Semi /= 0
           and then Dot /= 0
           and then Dot < Semi;
      end Call_Has_Selected_Name;

      function Call_Has_Access_Dereference return Boolean is
         Code  : constant String := Normalized_Line (Statement_Raw);
         Semi  : constant Natural := Ada.Strings.Fixed.Index (Code, ";");
         Deref : constant Natural := Ada.Strings.Fixed.Index (Code, ".all");
      begin
         --  Explicit dereference calls through access-to-subprogram objects,
         --  for example ``Callback.all;`` and ``Callback.all (X);``, are
         --  ordinary call statements with a richer Ada name shape.  Preserve
         --  only that bounded syntax fingerprint here.
         return Semi /= 0
           and then Deref /= 0
           and then Deref < Semi;
      end Call_Has_Access_Dereference;

      function Call_Has_Attribute_Name return Boolean is
         Code      : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Statement_Raw);
         Semi      : constant Natural := Ada.Strings.Fixed.Index (Code, ";");
         Tick      : constant Natural := Ada.Strings.Fixed.Index (Code, "'");
         Tick_Open : constant Natural := Ada.Strings.Fixed.Index (Code, "'(");
      begin
         --  Attribute procedure calls such as ``T'Write (Stream, Item);`` are
         --  call statements whose callable name is an attribute reference, not
         --  a selected name or code-statement qualified expression.  Retain
         --  that bounded name shape without resolving the attribute.
         return Semi /= 0
           and then Tick /= 0
           and then Tick < Semi
           and then Tick_Open = 0;
      end Call_Has_Attribute_Name;


      function Call_Has_Entry_Family_Index return Boolean is
         Code       : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Statement_Raw);
         Semi       : constant Natural := Ada.Strings.Fixed.Index (Code, ";");
         Open_Count : Natural := 0;
      begin
         --  Ada entry-family calls may have an index group followed by a
         --  parameter group, for example ``Server.Family (Index) (Item);``.
         --  Retain that statement target shape as bounded metadata only; the
         --  parser does not resolve whether the target is actually an entry.
         if Semi = 0 then
            return False;
         end if;

         for I in Code'First .. Semi loop
            if Code (I) = '(' then
               Open_Count := Open_Count + 1;
            end if;
         end loop;

         return Open_Count > 1;
      end Call_Has_Entry_Family_Index;



      procedure Mark_Delay_Details (Line : String; Is_Alternative : Boolean := False) is
         Code : constant String := Normalized_Line (Line);
      begin
         --  Delay statements are executable statement syntax both as plain
         --  statements and as selective-accept delay alternatives introduced
         --  by ``or``.  Retain only bounded syntax-shape metadata here:
         --  relative vs delay-until and, when applicable, alternative shape.
         Mark_Statement_Kind (Analysis, Statement_Delay);

         if Is_Alternative then
            Mark_Statement_Kind (Analysis, Statement_Delay_Alternative);
         end if;

         if Starts_With_Word (Trim (Code), "delay until") then
            Mark_Statement_Kind (Analysis, Statement_Delay_Until);
            if Is_Alternative then
               Mark_Statement_Kind
                 (Analysis, Statement_Delay_Alternative_Until);
            end if;
         else
            Mark_Statement_Kind (Analysis, Statement_Delay_Relative);
            if Is_Alternative then
               Mark_Statement_Kind
                 (Analysis, Statement_Delay_Alternative_Relative);
            end if;
         end if;
      end Mark_Delay_Details;


      function Tail_After_Leading_Word (Line, Word : String) return String;

      procedure Mark_Abort_Target_Details (Line : String) is
         Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
         Tail : constant String := Trim (Tail_After_Leading_Word (Code, "abort"));
      begin
         --  Ada abort statements name one or more task objects.  Retain only
         --  bounded syntactic target-shape metadata: selected-name targets
         --  and comma-separated target lists are useful parser fingerprints,
         --  but they are not declarations and do not create navigation data.
         if Tail'Length = 0 then
            return;
         end if;

         if Ada.Strings.Fixed.Index (Tail, ".") /= 0 then
            Mark_Statement_Kind (Analysis, Statement_Abort_Selected_Target);
         end if;

         if Ada.Strings.Fixed.Index (Tail, ",") /= 0 then
            Mark_Statement_Kind (Analysis, Statement_Abort_Multiple_Targets);
         end if;
      end Mark_Abort_Target_Details;




      procedure Mark_Accept_Details (Line : String) is
         Code       : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
         Tail       : constant String := Trim (Tail_After_Leading_Word (Code, "accept"));
         Stop       : Natural := Ada.Strings.Fixed.Index (Tail, "do");
         Semi       : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Open_Count : Natural := 0;
         Has_Colon  : Boolean := False;
      begin
         --  Accept statements have optional entry-family indexes and
         --  parameter profiles.  Retain only bounded syntactic shape metadata
         --  for the statement parser: a colon-bearing parenthesized profile
         --  and a second parenthesized group before ``do``/``;`` indicate
         --  accept-profile and entry-family forms without creating symbols.
         Mark_Statement_Kind (Analysis, Statement_Accept);
         if Tail'Length = 0 then
            return;
         end if;

         if Stop = 0 or else (Semi /= 0 and then Semi < Stop) then
            Stop := Semi;
         end if;

         if Stop = 0 then
            Stop := Tail'Last + 1;
         end if;

         for I in Tail'First .. Natural'Min (Tail'Last, Stop - 1) loop
            if Tail (I) = '(' then
               Open_Count := Open_Count + 1;
            elsif Tail (I) = ':' then
               Has_Colon := True;
            end if;
         end loop;

         if Has_Colon then
            Mark_Statement_Kind (Analysis, Statement_Accept_With_Profile);
         end if;

         if Open_Count > 1 or else (Open_Count = 1 and then not Has_Colon) then
            Mark_Statement_Kind (Analysis, Statement_Accept_Entry_Family_Index);
         end if;

         if Has_Token (Tail, "do") then
            Mark_Statement_Kind (Analysis, Statement_Accept_Body);
         end if;
      end Mark_Accept_Details;

      procedure Mark_Requeue_Target_Details (Line : String) is
         Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
         Tail : constant String := Trim (Tail_After_Leading_Word (Code, "requeue"));
         Semi : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Dot  : constant Natural := Ada.Strings.Fixed.Index (Tail, ".");
         Open : constant Natural := Ada.Strings.Fixed.Index (Tail, "(");
      begin
         --  Ada requeue statements target an entry name.  Retain bounded
         --  syntactic target-shape metadata for selected entry names and
         --  entry-family indexes/argument lists without resolving the entry
         --  or creating declaration/navigation data.
         if Tail'Length = 0 then
            return;
         end if;

         if Dot /= 0 and then (Semi = 0 or else Dot < Semi) then
            Mark_Statement_Kind
              (Analysis, Statement_Requeue_Selected_Target);
         end if;

         if Open /= 0 and then (Semi = 0 or else Open < Semi) then
            Mark_Statement_Kind
              (Analysis, Statement_Requeue_With_Arguments);
         end if;
      end Mark_Requeue_Target_Details;

      procedure Mark_Assignment_Target_Details (Line : String) is
         Code   : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
         Assign : constant Natural := Ada.Strings.Fixed.Index (Code, ":=");
      begin
         --  Assignment statements are executable statement syntax, not
         --  declarations.  Retain a conservative target-shape fingerprint so
         --  selected component, indexed component, and slice assignments are
         --  distinguishable without building a full expression/name AST.
         if Assign = 0 or else Assign = Code'First then
            return;
         end if;

         declare
            Target : constant String := Trim (Code (Code'First .. Assign - 1));
            Open   : constant Natural := Ada.Strings.Fixed.Index (Target, "(");
            Close  : constant Natural := Ada.Strings.Fixed.Index (Target, ")");
            Range_Op : constant Natural := Ada.Strings.Fixed.Index (Target, "..");

            function Has_Selected_Dot return Boolean is
            begin
               for I in Target'Range loop
                  if Target (I) = '.'
                    and then (I = Target'First or else Target (I - 1) /= '.')
                    and then (I = Target'Last or else Target (I + 1) /= '.')
                  then
                     return True;
                  end if;
               end loop;

               return False;
            end Has_Selected_Dot;
         begin
            if Target'Length = 0 then
               return;
            end if;

            if Has_Selected_Dot then
               Mark_Statement_Kind
                 (Analysis, Statement_Assignment_Selected_Target);
            end if;

            if Ada.Strings.Fixed.Index (Lower (Target), ".all") /= 0 then
               Mark_Statement_Kind
                 (Analysis, Statement_Assignment_Access_Dereference);
            end if;

            if Open /= 0 then
               Mark_Statement_Kind
                 (Analysis, Statement_Assignment_Indexed_Target);

               if Range_Op /= 0
                 and then Range_Op > Open
                 and then (Close = 0 or else Range_Op < Close)
               then
                  Mark_Statement_Kind
                    (Analysis, Statement_Assignment_Slice_Target);
               end if;
            end if;
         end;
      end Mark_Assignment_Target_Details;

      function Tail_After_Arrow (Line : String) return String
        renames Tail_Analysis_Helpers.Tail_After_Arrow;

      function Tail_After_Leading_Word (Line, Word : String) return String
        renames Tail_Analysis_Helpers.Tail_After_Leading_Word;

      function Looks_Like_Alternative_Call (Tail : String) return Boolean is
         Semi : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
      begin
         if Tail'Length = 0
           or else Semi = 0
           or else Starts_With_Word (Tail, "null")
           or else Starts_With_Word (Tail, "raise")
           or else Starts_With_Word (Tail, "return")
           or else Starts_With_Word (Tail, "if")
           or else Starts_With_Word (Tail, "case")
           or else Starts_With_Word (Tail, "loop")
           or else Starts_With_Word (Tail, "delay")
           or else Starts_With_Word (Tail, "requeue")
           or else Starts_With_Word (Tail, "abort")
           or else Starts_With_Word (Tail, "exit")
           or else Starts_With_Word (Tail, "goto")
           or else Ada.Strings.Fixed.Index (Tail, ":=") /= 0
         then
            return False;
         end if;

         if not ((Tail (Tail'First) >= 'a' and then Tail (Tail'First) <= 'z')
                 or else (Tail (Tail'First) >= 'A' and then Tail (Tail'First) <= 'Z'))
         then
            return False;
         end if;

         for J in Tail'First .. Semi loop
            if Tail (J) = ':' then
               return False;
            end if;
         end loop;

         return True;
      end Looks_Like_Alternative_Call;

      function Alternative_Call_Has_Arguments (Tail : String) return Boolean is
         Semi : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Open : constant Natural := Ada.Strings.Fixed.Index (Tail, "(");
      begin
         return Semi /= 0 and then Open /= 0 and then Open < Semi;
      end Alternative_Call_Has_Arguments;

      function Alternative_Call_Has_Named_Association (Tail : String) return Boolean is
         Semi  : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Arrow : constant Natural := Ada.Strings.Fixed.Index (Tail, "=>");
         Open  : constant Natural := Ada.Strings.Fixed.Index (Tail, "(");
      begin
         return Semi /= 0
           and then Open /= 0
           and then Arrow /= 0
           and then Open < Arrow
           and then Arrow < Semi;
      end Alternative_Call_Has_Named_Association;

      function Alternative_Call_Has_Selected_Name (Tail : String) return Boolean is
         Semi : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Dot  : constant Natural := Ada.Strings.Fixed.Index (Tail, ".");
      begin
         return Semi /= 0 and then Dot /= 0 and then Dot < Semi;
      end Alternative_Call_Has_Selected_Name;

      function Alternative_Call_Has_Access_Dereference
        (Tail : String) return Boolean
      is
         Semi : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Deref : constant Natural := Ada.Strings.Fixed.Index (Lower (Tail), ".all");
      begin
         --  Access-to-subprogram calls may use an explicit dereference such
         --  as ``Callback.all;`` or ``Callback.all (Arg);``.  Keep this as
         --  bounded statement-shape metadata without resolving the access
         --  object or treating ``all`` as a declaration/symbol.
         return Semi /= 0 and then Deref /= 0 and then Deref < Semi;
      end Alternative_Call_Has_Access_Dereference;

      function Alternative_Call_Has_Attribute_Name
        (Tail : String) return Boolean
      is
         Semi      : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Tick      : constant Natural := Ada.Strings.Fixed.Index (Tail, "'");
         Tick_Open : constant Natural := Ada.Strings.Fixed.Index (Tail, "'(");
      begin
         return Semi /= 0
           and then Tick /= 0
           and then Tick < Semi
           and then Tick_Open = 0;
      end Alternative_Call_Has_Attribute_Name;
      function Alternative_Call_Has_Entry_Family_Index
        (Tail : String) return Boolean
      is
         Semi       : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Open_Count : Natural := 0;
      begin
         if Semi = 0 then
            return False;
         end if;

         for I in Tail'First .. Semi loop
            if Tail (I) = '(' then
               Open_Count := Open_Count + 1;
            end if;
         end loop;

         return Open_Count > 1;
      end Alternative_Call_Has_Entry_Family_Index;


      function Looks_Like_Alternative_Code (Tail : String) return Boolean is
         Semi       : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Tick_Open  : constant Natural := Ada.Strings.Fixed.Index (Tail, "'(");
         Open_Paren : constant Natural := Ada.Strings.Fixed.Index (Tail, "(");
      begin
         return Tail'Length /= 0
           and then Semi /= 0
           and then Tick_Open /= 0
           and then Open_Paren /= 0
           and then Tick_Open < Semi
           and then Open_Paren < Semi
           and then Ada.Strings.Fixed.Index (Tail, ":=") = 0;
      end Looks_Like_Alternative_Code;

      function Has_Compact_Statement_Sequence (Line : String) return Boolean is
         Semi_Count : Natural := 0;
      begin
         --  Compact/generated Ada can place a complete control statement and
         --  its nested simple action on one physical line, for example
         --     if Ready then null; end if;
         --  Retain that source shape as bounded metadata without attempting
         --  to split the line into a recursive statement AST.
         for I in Line'Range loop
            if Line (I) = ';' then
               Semi_Count := Semi_Count + 1;
            end if;
         end loop;

         return Semi_Count > 1
           or else
             (Semi_Count > 0
              and then
                (Ada.Strings.Fixed.Index (Line, " then ") /= 0
                 or else Ada.Strings.Fixed.Index (Line, " else ") /= 0
                 or else Ada.Strings.Fixed.Index (Line, " end if") /= 0
                 or else Ada.Strings.Fixed.Index (Line, " end loop") /= 0
                 or else Ada.Strings.Fixed.Index (Line, " end select") /= 0));
      end Has_Compact_Statement_Sequence;

      procedure Mark_Compact_Then_Action_Details is
         Then_Pos : constant Natural := Ada.Strings.Fixed.Index (Statement_Line, " then ");
         Tail     : String (1 .. Statement_Line'Length) := (others => ' ');
         Last     : Natural := 0;
      begin
         --  Compact one-line conditionals may carry a complete simple action
         --  between ``then`` and the first semicolon, e.g.
         --     if Ready then Worker.Deliver (Item); end if;
         --  Preserve that visible action shape as bounded statement metadata
         --  without creating nested AST nodes or declaration/navigation symbols.
         if Then_Pos = 0
           or else Starts_With_Word (Statement_Line, "select")
         then
            return;
         end if;

         declare
            Start : constant Natural := Then_Pos + 6;
            Semi  : Natural := 0;
         begin
            if Start > Statement_Line'Last then
               return;
            end if;

            for I in Start .. Statement_Line'Last loop
               if Statement_Line (I) = ';' then
                  Semi := I;
                  exit;
               end if;
            end loop;

            if Semi = 0 then
               return;
            end if;

            declare
               Segment : constant String := Trim (Statement_Line (Start .. Semi));
            begin
               if Segment'Length = 0 then
                  return;
               end if;

               Tail (1 .. Segment'Length) := Segment;
               Last := Segment'Length;
            end;
         end;

         if Last = 0 then
            return;
         end if;

         declare
            Action : constant String := Tail (1 .. Last);
         begin
            Mark_Statement_Kind (Analysis, Statement_Then_Action);

            if Starts_With_Word (Action, "null") then
               Mark_Statement_Kind (Analysis, Statement_Null);
            elsif Starts_With_Word (Action, "return") then
               Mark_Statement_Kind (Analysis, Statement_Return);
               if Tail_After_Leading_Word (Action, "return") /= ";" then
                  Mark_Statement_Kind (Analysis, Statement_Return_With_Expression);
               end if;
            elsif Starts_With_Word (Action, "raise") then
               Mark_Statement_Kind (Analysis, Statement_Raise);
               declare
                  Remainder : constant String :=
                    Tail_After_Leading_Word (Action, "raise");
               begin
                  if Remainder = ";" then
                     Mark_Statement_Kind (Analysis, Statement_Raise_Reraise);
                  elsif Remainder'Length > 0 then
                     Mark_Statement_Kind
                       (Analysis, Statement_Raise_Exception_Name);
                  end if;
               end;
               if Has_Token (Action, "with") then
                  Mark_Statement_Kind (Analysis, Statement_Raise_With_Message);
               end if;
            elsif Ada.Strings.Fixed.Index (Action, ":=") /= 0 then
               Mark_Statement_Kind (Analysis, Statement_Assignment);
               Mark_Assignment_Target_Details (Action);
            elsif Looks_Like_Alternative_Code (Action) then
               Mark_Statement_Kind (Analysis, Statement_Code);
            elsif Looks_Like_Call_Statement (Action) then
               Mark_Statement_Kind (Analysis, Statement_Call);
               if Alternative_Call_Has_Arguments (Action) then
                  Mark_Statement_Kind (Analysis, Statement_Call_With_Arguments);
               end if;
               if Alternative_Call_Has_Named_Association (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_With_Named_Association);
               end if;
               if Alternative_Call_Has_Selected_Name (Action) then
                  Mark_Statement_Kind (Analysis, Statement_Call_Selected_Name);
               end if;
               if Alternative_Call_Has_Access_Dereference (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Access_Dereference);
               end if;
               if Alternative_Call_Has_Attribute_Name (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Attribute_Name);
               end if;
               if Alternative_Call_Has_Entry_Family_Index (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Entry_Family_Index);
               end if;
            end if;
         end;
      end Mark_Compact_Then_Action_Details;

      procedure Mark_Compact_Elsif_Action_Details is
         Elsif_Pos : constant Natural := Ada.Strings.Fixed.Index (Statement_Line, " elsif ");
         Tail      : String (1 .. Statement_Line'Length) := (others => ' ');
         Last      : Natural := 0;
      begin
         --  Compact one-line conditionals may carry a complete simple action
         --  after an elsif arm, for example
         --     if Ready then null; elsif Retry then Worker.Deliver (Item); end if;
         --  Retain that visible action shape as bounded parser metadata.  The
         --  action is not learned as a declaration and is not projected into
         --  Outline or semantic symbol rows.
         if Elsif_Pos = 0 then
            return;
         end if;

         declare
            Then_Pos : Natural := 0;
         begin
            if Statement_Line'Length < Elsif_Pos + 12 then
               return;
            end if;

            for I in Elsif_Pos + 7 .. Statement_Line'Last - 5 loop
               if Statement_Line (I .. I + 5) = " then " then
                  Then_Pos := I;
                  exit;
               end if;
            end loop;

            if Then_Pos = 0 then
               return;
            end if;

            declare
               Start : constant Natural := Then_Pos + 6;
               Semi  : Natural := 0;
            begin
               if Start > Statement_Line'Last then
                  return;
               end if;

               for I in Start .. Statement_Line'Last loop
                  if Statement_Line (I) = ';' then
                     Semi := I;
                     exit;
                  end if;
               end loop;

               if Semi = 0 then
                  return;
               end if;

               declare
                  Segment : constant String := Trim (Statement_Line (Start .. Semi));
               begin
                  if Segment'Length = 0 then
                     return;
                  end if;

                  Tail (1 .. Segment'Length) := Segment;
                  Last := Segment'Length;
               end;
            end;
         end;

         if Last = 0 then
            return;
         end if;

         declare
            Action : constant String := Tail (1 .. Last);
         begin
            Mark_Statement_Kind (Analysis, Statement_Elsif_Action);

            if Starts_With_Word (Action, "null") then
               Mark_Statement_Kind (Analysis, Statement_Null);
            elsif Starts_With_Word (Action, "return") then
               Mark_Statement_Kind (Analysis, Statement_Return);
               if Tail_After_Leading_Word (Action, "return") /= ";" then
                  Mark_Statement_Kind (Analysis, Statement_Return_With_Expression);
               end if;
            elsif Starts_With_Word (Action, "raise") then
               Mark_Statement_Kind (Analysis, Statement_Raise);
               declare
                  Remainder : constant String :=
                    Tail_After_Leading_Word (Action, "raise");
               begin
                  if Remainder = ";" then
                     Mark_Statement_Kind (Analysis, Statement_Raise_Reraise);
                  elsif Remainder'Length > 0 then
                     Mark_Statement_Kind
                       (Analysis, Statement_Raise_Exception_Name);
                  end if;
               end;
               if Has_Token (Action, "with") then
                  Mark_Statement_Kind (Analysis, Statement_Raise_With_Message);
               end if;
            elsif Ada.Strings.Fixed.Index (Action, ":=") /= 0 then
               Mark_Statement_Kind (Analysis, Statement_Assignment);
               Mark_Assignment_Target_Details (Action);
            elsif Looks_Like_Alternative_Code (Action) then
               Mark_Statement_Kind (Analysis, Statement_Code);
            elsif Looks_Like_Call_Statement (Action) then
               Mark_Statement_Kind (Analysis, Statement_Call);
               if Alternative_Call_Has_Arguments (Action) then
                  Mark_Statement_Kind (Analysis, Statement_Call_With_Arguments);
               end if;
               if Alternative_Call_Has_Named_Association (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_With_Named_Association);
               end if;
               if Alternative_Call_Has_Selected_Name (Action) then
                  Mark_Statement_Kind (Analysis, Statement_Call_Selected_Name);
               end if;
               if Alternative_Call_Has_Access_Dereference (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Access_Dereference);
               end if;
               if Alternative_Call_Has_Attribute_Name (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Attribute_Name);
               end if;
               if Alternative_Call_Has_Entry_Family_Index (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Entry_Family_Index);
               end if;
            end if;
         end;
      end Mark_Compact_Elsif_Action_Details;

      procedure Mark_Compact_Else_Action_Details is
         Else_Pos : constant Natural := Ada.Strings.Fixed.Index (Statement_Line, " else ");
         Tail     : String (1 .. Statement_Line'Length) := (others => ' ');
         Last     : Natural := 0;
      begin
         --  Compact one-line conditionals may carry a complete simple action
         --  between ``else`` and the following semicolon, e.g.
         --     if Failed then Recover; else Cleanup (Reason => Timeout); end if;
         --  Preserve that visible else-action shape as bounded statement
         --  metadata without learning declarations or building a nested AST.
         if Else_Pos = 0
           or else Starts_With_Word (Statement_Line, "select")
         then
            return;
         end if;

         declare
            Start : constant Natural := Else_Pos + 6;
            Semi  : Natural := 0;
         begin
            if Start > Statement_Line'Last then
               return;
            end if;

            for I in Start .. Statement_Line'Last loop
               if Statement_Line (I) = ';' then
                  Semi := I;
                  exit;
               end if;
            end loop;

            if Semi = 0 then
               return;
            end if;

            declare
               Segment : constant String := Trim (Statement_Line (Start .. Semi));
            begin
               if Segment'Length = 0 then
                  return;
               end if;

               Tail (1 .. Segment'Length) := Segment;
               Last := Segment'Length;
            end;
         end;

         if Last = 0 then
            return;
         end if;

         declare
            Action : constant String := Tail (1 .. Last);
         begin
            Mark_Statement_Kind (Analysis, Statement_Else_Action);

            if Starts_With_Word (Action, "null") then
               Mark_Statement_Kind (Analysis, Statement_Null);
            elsif Starts_With_Word (Action, "return") then
               Mark_Statement_Kind (Analysis, Statement_Return);
               if Tail_After_Leading_Word (Action, "return") /= ";" then
                  Mark_Statement_Kind (Analysis, Statement_Return_With_Expression);
               end if;
            elsif Starts_With_Word (Action, "raise") then
               Mark_Statement_Kind (Analysis, Statement_Raise);
               declare
                  Remainder : constant String :=
                    Tail_After_Leading_Word (Action, "raise");
               begin
                  if Remainder = ";" then
                     Mark_Statement_Kind (Analysis, Statement_Raise_Reraise);
                  elsif Remainder'Length > 0 then
                     Mark_Statement_Kind
                       (Analysis, Statement_Raise_Exception_Name);
                  end if;
               end;
               if Has_Token (Action, "with") then
                  Mark_Statement_Kind (Analysis, Statement_Raise_With_Message);
               end if;
            elsif Ada.Strings.Fixed.Index (Action, ":=") /= 0 then
               Mark_Statement_Kind (Analysis, Statement_Assignment);
               Mark_Assignment_Target_Details (Action);
            elsif Looks_Like_Alternative_Code (Action) then
               Mark_Statement_Kind (Analysis, Statement_Code);
            elsif Looks_Like_Call_Statement (Action) then
               Mark_Statement_Kind (Analysis, Statement_Call);
               if Alternative_Call_Has_Arguments (Action) then
                  Mark_Statement_Kind (Analysis, Statement_Call_With_Arguments);
               end if;
               if Alternative_Call_Has_Named_Association (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_With_Named_Association);
               end if;
               if Alternative_Call_Has_Selected_Name (Action) then
                  Mark_Statement_Kind (Analysis, Statement_Call_Selected_Name);
               end if;
               if Alternative_Call_Has_Access_Dereference (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Access_Dereference);
               end if;
               if Alternative_Call_Has_Attribute_Name (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Attribute_Name);
               end if;
               if Alternative_Call_Has_Entry_Family_Index (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Entry_Family_Index);
               end if;
            end if;
         end;
      end Mark_Compact_Else_Action_Details;


      procedure Mark_Compact_Loop_Action_Details is
         Loop_Pos : Natural := Ada.Strings.Fixed.Index (Statement_Line, " loop ");
         Tail     : String (1 .. Statement_Line'Length) := (others => ' ');
         Last     : Natural := 0;
      begin
         --  Compact one-line loops may carry a complete simple action between
         --  the loop header and ``end loop``.  Retain that visible body action
         --  shape as bounded statement metadata without creating a statement
         --  tree, Outline row, semantic symbol, scope, declaration, or target.
         if Loop_Pos = 0 then
            if Starts_With_Word (Statement_Line, "loop")
              and then Statement_Line'Length >= 5
            then
               Loop_Pos := Statement_Line'First - 1;
            else
               return;
            end if;
         end if;

         declare
            Start : constant Natural := Loop_Pos + 6;
            Semi  : Natural := 0;
         begin
            if Start > Statement_Line'Last then
               return;
            end if;

            for I in Start .. Statement_Line'Last loop
               if Statement_Line (I) = ';' then
                  Semi := I;
                  exit;
               end if;
            end loop;

            if Semi = 0 then
               return;
            end if;

            declare
               Segment : constant String := Trim (Statement_Line (Start .. Semi));
            begin
               if Segment'Length = 0
                 or else Starts_With_Word (Segment, "end")
               then
                  return;
               end if;

               Tail (1 .. Segment'Length) := Segment;
               Last := Segment'Length;
            end;
         end;

         if Last = 0 then
            return;
         end if;

         declare
            Action : constant String := Tail (1 .. Last);
         begin
            Mark_Statement_Kind (Analysis, Statement_Loop_Action);

            if Starts_With_Word (Action, "null") then
               Mark_Statement_Kind (Analysis, Statement_Null);
            elsif Starts_With_Word (Action, "return") then
               Mark_Statement_Kind (Analysis, Statement_Return);
               if Tail_After_Leading_Word (Action, "return") /= ";" then
                  Mark_Statement_Kind (Analysis, Statement_Return_With_Expression);
               end if;
            elsif Starts_With_Word (Action, "raise") then
               Mark_Statement_Kind (Analysis, Statement_Raise);
               declare
                  Remainder : constant String :=
                    Tail_After_Leading_Word (Action, "raise");
               begin
                  if Remainder = ";" then
                     Mark_Statement_Kind (Analysis, Statement_Raise_Reraise);
                  elsif Remainder'Length > 0 then
                     Mark_Statement_Kind
                       (Analysis, Statement_Raise_Exception_Name);
                  end if;
               end;
               if Has_Token (Action, "with") then
                  Mark_Statement_Kind (Analysis, Statement_Raise_With_Message);
               end if;
            elsif Ada.Strings.Fixed.Index (Action, ":=") /= 0 then
               Mark_Statement_Kind (Analysis, Statement_Assignment);
               Mark_Assignment_Target_Details (Action);
            elsif Looks_Like_Alternative_Code (Action) then
               Mark_Statement_Kind (Analysis, Statement_Code);
            elsif Looks_Like_Call_Statement (Action) then
               Mark_Statement_Kind (Analysis, Statement_Call);
               if Alternative_Call_Has_Arguments (Action) then
                  Mark_Statement_Kind (Analysis, Statement_Call_With_Arguments);
               end if;
               if Alternative_Call_Has_Named_Association (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_With_Named_Association);
               end if;
               if Alternative_Call_Has_Selected_Name (Action) then
                  Mark_Statement_Kind (Analysis, Statement_Call_Selected_Name);
               end if;
               if Alternative_Call_Has_Access_Dereference (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Access_Dereference);
               end if;
               if Alternative_Call_Has_Attribute_Name (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Attribute_Name);
               end if;
               if Alternative_Call_Has_Entry_Family_Index (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Entry_Family_Index);
               end if;
            end if;
         end;
      end Mark_Compact_Loop_Action_Details;



      procedure Mark_Compact_Declare_Action_Details is
         Begin_Pos : constant Natural := Ada.Strings.Fixed.Index (Statement_Line, " begin ");
         Semi      : Natural := 0;
      begin
         --  Compact/generated declare blocks can place the declarative part,
         --  begin marker, and first simple action on one physical line, e.g.
         --     declare X : Natural := 0; begin Use (X); end;
         --  Retain the declare-block action shape as bounded parser metadata.
         --  The existing compact begin-action helper records the embedded
         --  simple action; this marker preserves that the action belonged to
         --  a compact declare block rather than an ordinary body begin line.
         if not Starts_With_Word (Statement_Line, "declare")
           or else Begin_Pos = 0
           or else Begin_Pos + 7 > Statement_Line'Last
         then
            return;
         end if;

         for I in Begin_Pos + 7 .. Statement_Line'Last loop
            if Statement_Line (I) = ';' then
               Semi := I;
               exit;
            end if;
         end loop;

         if Semi = 0 then
            return;
         end if;

         declare
            Segment : constant String :=
              Trim (Statement_Line (Begin_Pos + 7 .. Semi));
         begin
            if Segment'Length /= 0
              and then not Starts_With_Word (Segment, "end")
            then
               Mark_Statement_Kind (Analysis, Statement_Declare_Action);
            end if;
         end;
      end Mark_Compact_Declare_Action_Details;

      procedure Mark_Compact_Begin_Action_Details is
         Begin_Pos : constant Natural := Ada.Strings.Fixed.Index (Statement_Line, "begin ");
         Tail      : String (1 .. Statement_Line'Length) := (others => ' ');
         Last      : Natural := 0;
      begin
         --  Compact/generated Ada may put a handled sequence body action on
         --  the same physical line as ``begin``:
         --     begin Worker.Deliver (Item); end;
         --  Retain the immediately visible action shape as bounded metadata.
         --  This does not create a statement tree, Outline row, semantic
         --  symbol, declaration, scope, or navigation target.
         if Begin_Pos = 0 then
            return;
         end if;

         declare
            Start : constant Natural := Begin_Pos + 6;
            Semi  : Natural := 0;
         begin
            if Start > Statement_Line'Last then
               return;
            end if;

            for I in Start .. Statement_Line'Last loop
               if Statement_Line (I) = ';' then
                  Semi := I;
                  exit;
               end if;
            end loop;

            if Semi = 0 then
               return;
            end if;

            declare
               Segment : constant String := Trim (Statement_Line (Start .. Semi));
            begin
               if Segment'Length = 0
                 or else Starts_With_Word (Segment, "end")
               then
                  return;
               end if;

               Tail (1 .. Segment'Length) := Segment;
               Last := Segment'Length;
            end;
         end;

         if Last = 0 then
            return;
         end if;

         declare
            Action : constant String := Tail (1 .. Last);
         begin
            Mark_Statement_Kind (Analysis, Statement_Begin_Action);

            if Starts_With_Word (Action, "null") then
               Mark_Statement_Kind (Analysis, Statement_Null);
            elsif Starts_With_Word (Action, "return") then
               Mark_Statement_Kind (Analysis, Statement_Return);
               if Tail_After_Leading_Word (Action, "return") /= ";" then
                  Mark_Statement_Kind (Analysis, Statement_Return_With_Expression);
               end if;
            elsif Starts_With_Word (Action, "raise") then
               Mark_Statement_Kind (Analysis, Statement_Raise);
               declare
                  Remainder : constant String :=
                    Tail_After_Leading_Word (Action, "raise");
               begin
                  if Remainder = ";" then
                     Mark_Statement_Kind (Analysis, Statement_Raise_Reraise);
                  elsif Remainder'Length > 0 then
                     Mark_Statement_Kind
                       (Analysis, Statement_Raise_Exception_Name);
                  end if;
               end;
               if Has_Token (Action, "with") then
                  Mark_Statement_Kind (Analysis, Statement_Raise_With_Message);
               end if;
            elsif Ada.Strings.Fixed.Index (Action, ":=") /= 0 then
               Mark_Statement_Kind (Analysis, Statement_Assignment);
               Mark_Assignment_Target_Details (Action);
            elsif Looks_Like_Alternative_Code (Action) then
               Mark_Statement_Kind (Analysis, Statement_Code);
            elsif Looks_Like_Call_Statement (Action) then
               Mark_Statement_Kind (Analysis, Statement_Call);
               if Alternative_Call_Has_Arguments (Action) then
                  Mark_Statement_Kind (Analysis, Statement_Call_With_Arguments);
               end if;
               if Alternative_Call_Has_Named_Association (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_With_Named_Association);
               end if;
               if Alternative_Call_Has_Selected_Name (Action) then
                  Mark_Statement_Kind (Analysis, Statement_Call_Selected_Name);
               end if;
               if Alternative_Call_Has_Access_Dereference (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Access_Dereference);
               end if;
               if Alternative_Call_Has_Attribute_Name (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Attribute_Name);
               end if;
               if Alternative_Call_Has_Entry_Family_Index (Action) then
                  Mark_Statement_Kind
                    (Analysis, Statement_Call_Entry_Family_Index);
               end if;
            end if;
         end;
      end Mark_Compact_Begin_Action_Details;

      procedure Mark_Compact_Statement_Details is
      begin
         if not Has_Compact_Statement_Sequence (Statement_Line) then
            return;
         end if;

         Mark_Statement_Kind (Analysis, Statement_Compact_Sequence);
         Mark_Compact_Loop_Action_Details;
         Mark_Compact_Declare_Action_Details;
         Mark_Compact_Begin_Action_Details;
         Mark_Compact_Then_Action_Details;
         Mark_Compact_Elsif_Action_Details;
         Mark_Compact_Else_Action_Details;

         if (Ada.Strings.Fixed.Index (Statement_Line, " null;") /= 0
             or else Ada.Strings.Fixed.Index (Statement_Line, "=> null;") /= 0)
           and then not Starts_With_Word (Statement_Line, "if")
           and then not Starts_With_Word (Statement_Line, "elsif")
           and then not Starts_With_Word (Statement_Line, "while")
           and then not Starts_With_Word (Statement_Line, "for")
           and then not Starts_With_Word (Statement_Line, "loop")
         then
            Mark_Statement_Kind (Analysis, Statement_Null);
         end if;

         if Ada.Strings.Fixed.Index (Statement_Line, " end if") /= 0 then
            Mark_Statement_Kind (Analysis, Statement_End_If);
         end if;

         if Ada.Strings.Fixed.Index (Statement_Line, " end case") /= 0
           and then not In_Record
         then
            Mark_Statement_Kind (Analysis, Statement_End_Case);
         end if;

         if Ada.Strings.Fixed.Index (Statement_Line, " end loop") /= 0 then
            Mark_Statement_Kind (Analysis, Statement_End_Loop);
         end if;

         if Ada.Strings.Fixed.Index (Statement_Line, " end select") /= 0 then
            Mark_Statement_Kind (Analysis, Statement_End_Select);
         end if;

         if Ada.Strings.Fixed.Index (Statement_Line, " end;") /= 0 then
            Mark_Statement_Kind (Analysis, Statement_End_Block);
         end if;

         if Ada.Strings.Fixed.Index (Statement_Line, " else ") /= 0 then
            Mark_Statement_Kind (Analysis, Statement_Else);
         end if;
      end Mark_Compact_Statement_Details;

      procedure Mark_Raise_Details (Tail : String) is
         Remainder : constant String := Tail_After_Leading_Word (Tail, "raise");
      begin
         --  Ada permits both a bare re-raise (``raise;``) inside handlers
         --  and explicit exception-name raises.  Keep that statement shape as
         --  bounded parser metadata without resolving the exception symbol or
         --  parsing the optional message expression.
         if Remainder = ";" then
            Mark_Statement_Kind (Analysis, Statement_Raise_Reraise);
         elsif Remainder'Length > 0 then
            Mark_Statement_Kind (Analysis, Statement_Raise_Exception_Name);
         end if;

         if Has_Token (Tail, "with") then
            Mark_Statement_Kind (Analysis, Statement_Raise_With_Message);
         end if;
      end Mark_Raise_Details;

      procedure Mark_Goto_Details (Tail : String) is
         Remainder : constant String := Tail_After_Leading_Word (Tail, "goto");
      begin
         --  Ada goto statements target statement labels.  Keep the visible
         --  target shape as parser-owned statement metadata only; the label
         --  target is not learned as a declaration, Outline row, semantic
         --  symbol, scope, or navigation target.
         if Remainder'Length > 0
           and then Remainder /= ";"
         then
            Mark_Statement_Kind (Analysis, Statement_Goto_Label_Target);
         end if;
      end Mark_Goto_Details;

      procedure Mark_Pragma_Details
        (Tail : String; Is_Alternative : Boolean := False)
      is
         Open : constant Natural := Ada.Strings.Fixed.Index (Tail, "(");
         Semi : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
      begin
         --  Ada pragmas are allowed inside statement sequences and may also
         --  be the action after an executable alternative arrow.  Preserve
         --  both visible statement shapes as parser-owned metadata only;
         --  pragma names and arguments are not learned as declarations,
         --  Outline rows, semantic symbols, scopes, or navigation targets.
         Mark_Statement_Kind (Analysis, Statement_Pragma);
         if Semi /= 0 and then Open /= 0 and then Open < Semi then
            Mark_Statement_Kind (Analysis, Statement_Pragma_With_Arguments);
         end if;
         if Is_Alternative then
            Mark_Statement_Kind (Analysis, Statement_Alternative_Pragma);
         end if;
      end Mark_Pragma_Details;

      procedure Mark_Exit_Details (Tail : String) is
         Remainder : constant String := Tail_After_Leading_Word (Tail, "exit");
      begin
         --  Ada exit statements may name the loop being exited.  Keep that
         --  visible statement shape as metadata, without learning the loop name
         --  as a declaration, scope, Outline row, or navigation target.
         if Remainder'Length > 0
           and then Remainder /= ";"
           and then not Starts_With_Word (Remainder, "when")
         then
            Mark_Statement_Kind (Analysis, Statement_Exit_Named_Loop);
         end if;

         if Has_Token (Tail, "when") then
            Mark_Statement_Kind (Analysis, Statement_Exit_When);
         end if;
      end Mark_Exit_Details;

      procedure Mark_Alternative_Action (Tail : String) is
      begin
         --  Case/select/exception alternatives may carry a simple action after
         --  the ``=>`` marker.  Retain the immediately visible action shape as
         --  bounded statement metadata without attempting to parse the nested
         --  expression grammar or creating declaration/Outline symbols.
         if Tail'Length = 0 then
            return;
         elsif Starts_With_Word (Tail, "pragma") then
            Mark_Pragma_Details (Tail, Is_Alternative => True);
         elsif Starts_With_Word (Tail, "null") then
            Mark_Statement_Kind (Analysis, Statement_Null_Alternative);
         elsif Starts_With_Word (Tail, "raise") then
            Mark_Statement_Kind (Analysis, Statement_Raise);
            Mark_Statement_Kind (Analysis, Statement_Alternative_Raise);
            Mark_Raise_Details (Tail);
         elsif Starts_With_Word (Tail, "return") then
            Mark_Statement_Kind (Analysis, Statement_Return);
            Mark_Statement_Kind (Analysis, Statement_Alternative_Return);
            declare
               Return_Tail : constant String := Tail_After_Leading_Word (Tail, "return");
            begin
               if Return_Tail /= ";"
                 and then Ada.Strings.Fixed.Index
                   (Editor.Ada_Syntax_Core.Sanitize_Line (Return_Tail), ":") = 0
               then
                  Mark_Statement_Kind (Analysis, Statement_Return_With_Expression);
                  Mark_Statement_Kind
                    (Analysis, Statement_Alternative_Return_With_Expression);
               end if;
            end;
         elsif Starts_With_Word (Tail, "exit") then
            Mark_Statement_Kind (Analysis, Statement_Exit);
            Mark_Statement_Kind (Analysis, Statement_Alternative_Exit);
            Mark_Exit_Details (Tail);
         elsif Starts_With_Word (Tail, "goto") then
            Mark_Statement_Kind (Analysis, Statement_Goto);
            Mark_Statement_Kind (Analysis, Statement_Alternative_Goto);
            Mark_Goto_Details (Tail);
         elsif Starts_With_Word (Tail, "delay") then
            Mark_Statement_Kind (Analysis, Statement_Delay);
            Mark_Statement_Kind (Analysis, Statement_Alternative_Delay);
            if Starts_With_Word (Tail, "delay until") then
               Mark_Statement_Kind (Analysis, Statement_Delay_Until);
            else
               Mark_Statement_Kind (Analysis, Statement_Delay_Relative);
            end if;
         elsif Starts_With_Word (Tail, "requeue") then
            Mark_Statement_Kind (Analysis, Statement_Requeue);
            Mark_Statement_Kind (Analysis, Statement_Alternative_Requeue);
            Mark_Requeue_Target_Details (Tail);
            if Has_Token (Tail, "abort") then
               Mark_Statement_Kind (Analysis, Statement_Requeue_With_Abort);
            end if;
         elsif Starts_With_Word (Tail, "abort") then
            Mark_Statement_Kind (Analysis, Statement_Abort);
            Mark_Abort_Target_Details (Tail);
            Mark_Statement_Kind (Analysis, Statement_Alternative_Abort);
         elsif Ada.Strings.Fixed.Index (Tail, ":=") /= 0
           and then Ada.Strings.Fixed.Index (Tail, ":") =
             Ada.Strings.Fixed.Index (Tail, ":=")
         then
            Mark_Statement_Kind (Analysis, Statement_Assignment);
            Mark_Assignment_Target_Details (Tail);
            Mark_Statement_Kind (Analysis, Statement_Alternative_Assignment);
         elsif Looks_Like_Alternative_Code (Tail) then
            Mark_Statement_Kind (Analysis, Statement_Code);
            Mark_Statement_Kind (Analysis, Statement_Alternative_Code);
         elsif Looks_Like_Alternative_Call (Tail) then
            Mark_Statement_Kind (Analysis, Statement_Call);
            Mark_Statement_Kind (Analysis, Statement_Alternative_Call);
            if Alternative_Call_Has_Arguments (Tail) then
               Mark_Statement_Kind (Analysis, Statement_Call_With_Arguments);
            end if;
            if Alternative_Call_Has_Named_Association (Tail) then
               Mark_Statement_Kind (Analysis, Statement_Call_With_Named_Association);
            end if;
            if Alternative_Call_Has_Selected_Name (Tail) then
               Mark_Statement_Kind (Analysis, Statement_Call_Selected_Name);
            end if;
            if Alternative_Call_Has_Access_Dereference (Tail) then
               Mark_Statement_Kind
                 (Analysis, Statement_Call_Access_Dereference);
            end if;
            if Alternative_Call_Has_Attribute_Name (Tail) then
               Mark_Statement_Kind
                 (Analysis, Statement_Call_Attribute_Name);
            end if;
            if Alternative_Call_Has_Entry_Family_Index (Tail) then
               Mark_Statement_Kind
                 (Analysis, Statement_Call_Entry_Family_Index);
            end if;
         end if;
      end Mark_Alternative_Action;

      procedure Mark_Select_Else_Action (Tail : String) is
         Lower_Tail : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Tail));
         Else_Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower_Tail, "else");
      begin
         if Else_Pos = 0 then
            return;
         end if;

         declare
            Action : String := Tail (Else_Pos + 4 .. Tail'Last);
            Action_Code : String := Lower_Tail (Else_Pos + 4 .. Lower_Tail'Last);
            End_Pos : constant Natural :=
              Ada.Strings.Fixed.Index (Action_Code, "end select");
         begin
            if End_Pos /= 0 then
               for I in Action'First + End_Pos - 1 .. Action'Last loop
                  Action (I) := ' ';
               end loop;
               Action_Code :=
                 Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Action));
            end if;

            declare
               Clean_Action : constant String :=
                 Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Action));
               Clean_Lower : constant String := Trim (Action_Code);
            begin
               if Clean_Action'Length = 0
                 or else Clean_Action = ";"
               then
                  return;
               end if;

               Mark_Statement_Kind (Analysis, Statement_Select_Else_Action);
               Mark_Alternative_Action (Clean_Action);

               if Starts_With_Word (Clean_Lower, "null") then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Null);
               elsif Starts_With_Word (Clean_Lower, "return") then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Return);
               elsif Starts_With_Word (Clean_Lower, "raise") then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Raise);
               elsif Starts_With_Word (Clean_Lower, "exit") then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Exit);
               elsif Starts_With_Word (Clean_Lower, "goto") then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Goto);
               elsif Starts_With_Word (Clean_Lower, "delay") then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Delay);
                  if Starts_With_Word (Clean_Lower, "delay until") then
                     Mark_Statement_Kind (Analysis, Statement_Select_Else_Delay_Until);
                  else
                     Mark_Statement_Kind (Analysis, Statement_Select_Else_Delay_Relative);
                  end if;
               elsif Starts_With_Word (Clean_Lower, "requeue") then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Requeue);
                  if Has_Token (Clean_Lower, "abort") then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Else_Requeue_With_Abort);
                  end if;
               elsif Starts_With_Word (Clean_Lower, "abort") then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Abort);
               elsif Starts_With_Word (Clean_Lower, "pragma") then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Pragma);
                  if Ada.Strings.Fixed.Index (Clean_Lower, "(") /= 0 then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Else_Pragma_With_Arguments);
                  end if;
               elsif Ada.Strings.Fixed.Index (Clean_Lower, ":=") /= 0 then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Assignment);
               elsif Ada.Strings.Fixed.Index
                 (Clean_Action, Character'Val (39) & "(") /= 0
               then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Code);
               elsif Looks_Like_Alternative_Call (Clean_Action)
                 or else Looks_Like_Call_Statement (Clean_Action)
               then
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Call);
               else
                  Mark_Statement_Kind (Analysis, Statement_Select_Else_Code);
               end if;
            end;
         end;
      end Mark_Select_Else_Action;

      procedure Mark_Select_Delay_Fallback (Tail : String) is
         Lower_Tail : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Tail));
         Or_Delay_Pos : constant Natural :=
           Ada.Strings.Fixed.Index (Lower_Tail, " or delay");
      begin
         if Or_Delay_Pos = 0 then
            return;
         end if;

         declare
            Delay_Start : constant Natural := Or_Delay_Pos + 4;
            Delay_End   : Natural := 0;
         begin
            for I in Delay_Start .. Tail'Last loop
               if Tail (I) = ';' then
                  Delay_End := I;
                  exit;
               end if;
            end loop;

            if Delay_End = 0 then
               return;
            end if;

            declare
               Delay_Text : constant String :=
                 Trim (Tail (Delay_Start .. Delay_End));
               Delay_Lower : constant String :=
                 Trim (Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Delay_Text)));
               Action : String := Tail (Delay_End + 1 .. Tail'Last);
               Action_Code : String :=
                 Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Action));
               End_Pos : constant Natural :=
                 Ada.Strings.Fixed.Index (Action_Code, "end select");
            begin
               Mark_Statement_Kind (Analysis, Statement_Select_Delay_Fallback);
               Mark_Delay_Details (Delay_Text);
               if Starts_With_Word (Delay_Lower, "delay until") then
                  Mark_Statement_Kind
                    (Analysis, Statement_Select_Delay_Fallback_Until);
               else
                  Mark_Statement_Kind
                    (Analysis, Statement_Select_Delay_Fallback_Relative);
               end if;

               if End_Pos /= 0 then
                  for I in Action'First + End_Pos - 1 .. Action'Last loop
                     Action (I) := ' ';
                  end loop;
                  Action_Code :=
                    Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Action));
               end if;

               declare
                  Clean_Action : constant String :=
                    Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Action));
                  Clean_Lower : constant String := Trim (Action_Code);
               begin
                  if Clean_Action'Length = 0
                    or else Clean_Action = ";"
                  then
                     return;
                  end if;

                  Mark_Statement_Kind
                    (Analysis, Statement_Select_Delay_Fallback_Action);
                  Mark_Alternative_Action (Clean_Action);

                  if Starts_With_Word (Clean_Lower, "null") then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Null);
                  elsif Starts_With_Word (Clean_Lower, "return") then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Return);
                  elsif Starts_With_Word (Clean_Lower, "raise") then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Raise);
                  elsif Starts_With_Word (Clean_Lower, "exit") then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Exit);
                  elsif Starts_With_Word (Clean_Lower, "goto") then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Goto);
                  elsif Starts_With_Word (Clean_Lower, "delay") then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Delay);
                     if Starts_With_Word (Clean_Lower, "delay until") then
                        Mark_Statement_Kind
                          (Analysis, Statement_Select_Delay_Fallback_Delay_Until);
                     else
                        Mark_Statement_Kind
                          (Analysis, Statement_Select_Delay_Fallback_Delay_Relative);
                     end if;
                  elsif Starts_With_Word (Clean_Lower, "requeue") then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Requeue);
                     if Has_Token (Clean_Lower, "abort") then
                        Mark_Statement_Kind
                          (Analysis,
                           Statement_Select_Delay_Fallback_Requeue_With_Abort);
                     end if;
                  elsif Starts_With_Word (Clean_Lower, "abort") then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Abort);
                  elsif Starts_With_Word (Clean_Lower, "pragma") then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Pragma);
                     if Ada.Strings.Fixed.Index (Clean_Lower, "(") /= 0 then
                        Mark_Statement_Kind
                          (Analysis,
                           Statement_Select_Delay_Fallback_Pragma_With_Arguments);
                     end if;
                  elsif Ada.Strings.Fixed.Index (Clean_Lower, ":=") /= 0 then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Assignment);
                  elsif Ada.Strings.Fixed.Index
                    (Clean_Action, Character'Val (39) & "(") /= 0
                  then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Code);
                  elsif Looks_Like_Alternative_Call (Clean_Action)
                    or else Looks_Like_Call_Statement (Clean_Action)
                  then
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Call);
                     if Alternative_Call_Has_Arguments (Clean_Action) then
                        Mark_Statement_Kind
                          (Analysis,
                           Statement_Select_Delay_Fallback_Call_With_Arguments);
                     end if;
                     if Alternative_Call_Has_Named_Association (Clean_Action) then
                        Mark_Statement_Kind
                          (Analysis,
                           Statement_Select_Delay_Fallback_Call_With_Named_Association);
                     end if;
                     if Alternative_Call_Has_Selected_Name (Clean_Action) then
                        Mark_Statement_Kind
                          (Analysis,
                           Statement_Select_Delay_Fallback_Call_Selected_Name);
                     end if;
                     if Alternative_Call_Has_Access_Dereference (Clean_Action) then
                        Mark_Statement_Kind
                          (Analysis,
                           Statement_Select_Delay_Fallback_Call_Access_Dereference);
                     end if;
                     if Alternative_Call_Has_Entry_Family_Index (Clean_Action) then
                        Mark_Statement_Kind
                          (Analysis,
                           Statement_Select_Delay_Fallback_Call_Entry_Family_Index);
                     end if;
                  else
                     Mark_Statement_Kind
                       (Analysis, Statement_Select_Delay_Fallback_Code);
                  end if;
               end;
            end;
         end;
      end Mark_Select_Delay_Fallback;

      procedure Mark_Select_Then_Abort_Fallback (Tail : String) is
         Lower_Tail : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Tail));
         Then_Abort_Pos : constant Natural :=
           Ada.Strings.Fixed.Index (Lower_Tail, " then abort");
      begin
         if Then_Abort_Pos = 0 then
            return;
         end if;

         Mark_Statement_Kind (Analysis, Statement_Select_Then_Abort_Fallback);
         Mark_Statement_Kind (Analysis, Statement_Select_Abortable_Call);
         Mark_Statement_Kind (Analysis, Statement_Then_Abort_Alternative);

         declare
            Action : String := Tail (Then_Abort_Pos + 11 .. Tail'Last);
            Action_Code : String :=
              Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Action));
            End_Pos : constant Natural :=
              Ada.Strings.Fixed.Index (Action_Code, "end select");
         begin
            if End_Pos /= 0 then
               for I in Action'First + End_Pos - 1 .. Action'Last loop
                  Action (I) := ' ';
               end loop;
            end if;

            declare
               Clean_Action : constant String :=
                 Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Action));
            begin
               if Clean_Action'Length /= 0
                 and then Clean_Action /= ";"
               then
                  Mark_Statement_Kind (Analysis, Statement_Then_Abort_Action);
                  Mark_Alternative_Action (Clean_Action);
               end if;
            end;
         end;
      end Mark_Select_Then_Abort_Fallback;

      procedure Mark_Select_Terminate_Fallback (Tail : String) is
         Lower_Tail : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Tail));
      begin
         if Ada.Strings.Fixed.Index (Lower_Tail, " or terminate") /= 0 then
            Mark_Statement_Kind (Analysis, Statement_Select_Terminate_Fallback);
            Mark_Statement_Kind (Analysis, Statement_Terminate_Alternative);
         end if;
      end Mark_Select_Terminate_Fallback;

      function Select_Entry_Call_Text (Tail : String) return String is
         Lower_Tail : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Tail));
         Else_Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower_Tail, "else");
      begin
         if Else_Pos = 0 then
            return Tail;
         elsif Else_Pos = Tail'First then
            return "";
         else
            return Tail (Tail'First .. Else_Pos - 1);
         end if;
      end Select_Entry_Call_Text;

      procedure Mark_Select_Entry_Call_Details (Tail : String) is
         Entry_Call : constant String := Select_Entry_Call_Text (Tail);
      begin
         if Ada.Strings.Fixed.Index
              (Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Tail)), "else") = 0
         then
            Mark_Alternative_Action (Entry_Call);
         else
            Mark_Statement_Kind (Analysis, Statement_Call);
            if Alternative_Call_Has_Arguments (Entry_Call) then
               Mark_Statement_Kind (Analysis, Statement_Call_With_Arguments);
            end if;
            if Alternative_Call_Has_Named_Association (Entry_Call) then
               Mark_Statement_Kind (Analysis, Statement_Call_With_Named_Association);
            end if;
            if Alternative_Call_Has_Selected_Name (Entry_Call) then
               Mark_Statement_Kind (Analysis, Statement_Call_Selected_Name);
            end if;
            if Alternative_Call_Has_Access_Dereference (Entry_Call) then
               Mark_Statement_Kind
                 (Analysis, Statement_Call_Access_Dereference);
            end if;
            if Alternative_Call_Has_Attribute_Name (Entry_Call) then
               Mark_Statement_Kind
                 (Analysis, Statement_Call_Attribute_Name);
            end if;
            if Alternative_Call_Has_Entry_Family_Index (Entry_Call) then
               Mark_Statement_Kind
                 (Analysis, Statement_Call_Entry_Family_Index);
            end if;
         end if;
      end Mark_Select_Entry_Call_Details;

      function Looks_Like_Select_Entry_Call_Tail (Tail : String) return Boolean is
         Sanitized : constant String :=
           Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Tail));
      begin
         if Sanitized'Length = 0
           or else Sanitized = ";"
           or else Starts_With_Word (Sanitized, "then abort")
           or else Starts_With_Word (Sanitized, "delay")
           or else Starts_With_Word (Sanitized, "accept")
           or else Starts_With_Word (Sanitized, "terminate")
           or else Starts_With_Word (Sanitized, "else")
           or else Starts_With_Word (Sanitized, "or")
         then
            return False;
         end if;

         return Ada.Strings.Fixed.Index (Sanitized, ";") /= 0;
      end Looks_Like_Select_Entry_Call_Tail;



      procedure Mark_Compact_Case_Alternative_Details is
         I : Natural := Statement_Line'First;
      begin
         --  Compact/generated Ada may place an entire case statement on one
         --  physical line:
         --     case Mode is when A => Use_A; when others => null; end case;
         --  Preserve each visible executable alternative action as bounded
         --  statement metadata.  Record variant parts remain excluded because
         --  their ``case``/``when`` syntax is record-shape metadata, not an
         --  executable statement sequence.
         if In_Record
           or else not Starts_With_Word (Statement_Line, "case")
         then
            return;
         end if;

         while I < Statement_Line'Last loop
            if Statement_Line (I) = '='
              and then Statement_Line (I + 1) = '>'
            then
               declare
                  Start : constant Natural := I + 2;
                  Semi  : Natural := 0;
               begin
                  if Start > Statement_Line'Last then
                     return;
                  end if;

                  for J in Start .. Statement_Line'Last loop
                     if Statement_Line (J) = ';' then
                        Semi := J;
                        exit;
                     end if;
                  end loop;

                  if Semi = 0 then
                     return;
                  end if;

                  declare
                     Action : constant String := Trim (Statement_Line (Start .. Semi));
                  begin
                     if Action'Length /= 0 then
                        Mark_Statement_Kind (Analysis, Statement_When_Alternative);
                        Mark_Statement_Kind
                          (Analysis, Statement_Case_Alternative_Action);
                        Mark_Alternative_Action (Action);
                     end if;
                  end;

                  if Semi = Statement_Line'Last then
                     return;
                  end if;
                  I := Semi + 1;
               end;
            else
               I := I + 1;
            end if;
         end loop;
      end Mark_Compact_Case_Alternative_Details;

      procedure Mark_Compact_Exception_Handler_Details is
         I : Natural := Statement_Line'First;
      begin
         --  Compact/generated Ada may place one or more exception handlers on
         --  the same physical line as the exception marker:
         --     exception when Constraint_Error => null;
         --               when others => Recover;
         --  Retain each visible handler action as bounded statement metadata.
         --  The handler choices and actions are not learned as declarations,
         --  scopes, Outline rows, semantic symbols, or navigation targets.
         if not Starts_With_Word (Statement_Line, "exception") then
            return;
         end if;

         while I < Statement_Line'Last loop
            if Statement_Line (I) = '='
              and then Statement_Line (I + 1) = '>'
            then
               declare
                  Start : constant Natural := I + 2;
                  Semi  : Natural := 0;
               begin
                  if Start > Statement_Line'Last then
                     return;
                  end if;

                  for J in Start .. Statement_Line'Last loop
                     if Statement_Line (J) = ';' then
                        Semi := J;
                        exit;
                     end if;
                  end loop;

                  if Semi = 0 then
                     return;
                  end if;

                  declare
                     Action : constant String := Trim (Statement_Line (Start .. Semi));
                  begin
                     if Action'Length /= 0 then
                        Mark_Statement_Kind (Analysis, Statement_When_Alternative);
                        Mark_Statement_Kind
                          (Analysis, Statement_Exception_Handler_Action);
                        Mark_Alternative_Action (Action);
                     end if;
                  end;

                  if Semi = Statement_Line'Last then
                     return;
                  end if;
                  I := Semi + 1;
               end;
            else
               I := I + 1;
            end if;
         end loop;
      end Mark_Compact_Exception_Handler_Details;

      procedure Mark_Standalone_When_Alternative_Details is
         Arrow : constant Natural := Ada.Strings.Fixed.Index (Statement_Line, "=>");
         Semi  : Natural := 0;
      begin
         --  Exception and case alternatives are often formatted with one
         --  ``when`` per physical line.  Retain the action after ``=>`` using
         --  the same bounded metadata path as compact alternatives.
         if not Starts_With_Word (Statement_Line, "when")
           or else In_Record
           or else Arrow = 0
           or else Arrow + 2 > Statement_Line'Last
         then
            return;
         end if;

         for J in Arrow + 2 .. Statement_Line'Last loop
            if Statement_Line (J) = ';' then
               Semi := J;
               exit;
            end if;
         end loop;

         if Semi = 0 then
            Semi := Statement_Line'Last;
         end if;

         declare
            Action : constant String := Trim (Statement_Line (Arrow + 2 .. Semi));
         begin
            if Action'Length /= 0 then
               Mark_Statement_Kind (Analysis, Statement_When_Alternative);
               Mark_Alternative_Action (Action);
            end if;
         end;
      end Mark_Standalone_When_Alternative_Details;

   begin
      if Trimmed'Length = 0 then
         return;
      end if;

      Mark_Leading_Statement_Labels;

      if Has_Leading_Named_Statement then
         if Starts_With_Word (Statement_Line, "for")
           or else Starts_With_Word (Statement_Line, "while")
           or else Starts_With_Word (Statement_Line, "loop")
         then
            Mark_Statement_Kind (Analysis, Statement_Named_Loop);
         elsif Starts_With_Word (Statement_Line, "declare")
           or else Starts_With_Word (Statement_Line, "begin")
         then
            Mark_Statement_Kind (Analysis, Statement_Named_Block);
         end if;
      end if;

      if Has_Compact_Statement_Sequence (Statement_Line) then
         Mark_Compact_Statement_Details;
      end if;

      if Starts_With_Word (Statement_Line, "case") then
         Mark_Compact_Case_Alternative_Details;
      end if;

      if Starts_With_Word (Statement_Line, "exception") then
         Mark_Statement_Kind (Analysis, Statement_Exception_Handler);
         Mark_Compact_Exception_Handler_Details;
      end if;

      if Starts_With_Word (Statement_Line, "when") then
         Mark_Standalone_When_Alternative_Details;
      end if;

      if Starts_With_Word (Statement_Line, "if") then
         Mark_Statement_Kind (Analysis, Statement_If);
      elsif Starts_With_Word (Statement_Line, "elsif") then
         Mark_Statement_Kind (Analysis, Statement_Elsif);
      elsif Starts_With_Word (Statement_Line, "else") then
         Mark_Statement_Kind (Analysis, Statement_Else);
      elsif Starts_With_Word (Statement_Line, "case") and then not In_Record then
         Mark_Statement_Kind (Analysis, Statement_Case);
      elsif Starts_With_Word (Statement_Line, "while") then
         Mark_Statement_Kind (Analysis, Statement_Loop);
         Mark_Statement_Kind (Analysis, Statement_While_Loop);
      elsif Starts_With_Word (Statement_Line, "for") then
         Mark_Statement_Kind (Analysis, Statement_For_Loop);
         if Has_Token (Statement_Line, "in") then
            Mark_Statement_Kind (Analysis, Statement_For_In_Loop);
         end if;
         if Has_Token (Statement_Line, "of") then
            Mark_Statement_Kind (Analysis, Statement_For_Of_Loop);
         end if;
         if Has_Token (Statement_Line, "reverse") then
            Mark_Statement_Kind (Analysis, Statement_For_Reverse_Loop);
         end if;
      elsif Starts_With_Word (Statement_Line, "loop") then
         Mark_Statement_Kind (Analysis, Statement_Loop);
      elsif Starts_With_Word (Statement_Line, "select") then
         Mark_Statement_Kind (Analysis, Statement_Select);
         declare
            Select_Tail : constant String :=
              Tail_After_Leading_Word (Statement_Raw, "select");
            Sanitized_Select_Tail : constant String :=
              Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Select_Tail));
         begin
            if Looks_Like_Select_Entry_Call_Tail (Select_Tail) then
               Mark_Statement_Kind (Analysis, Statement_Select_Entry_Call);
               Mark_Select_Entry_Call_Details (Select_Tail);
            end if;
            Mark_Select_Else_Action (Select_Tail);
            Mark_Select_Delay_Fallback (Select_Tail);
            Mark_Select_Then_Abort_Fallback (Select_Tail);
            Mark_Select_Terminate_Fallback (Select_Tail);
         end;
      elsif Starts_With_Word (Statement_Line, "or") then
         Mark_Statement_Kind (Analysis, Statement_Or_Alternative);
         declare
            Alternative_Tail : constant String :=
              Tail_After_Leading_Word (Statement_Raw, "or");
         begin
            if Starts_With_Word
              (Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Alternative_Tail)),
               "delay")
            then
               Mark_Delay_Details (Alternative_Tail, Is_Alternative => True);
            elsif Starts_With_Word
              (Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Alternative_Tail)),
               "accept")
            then
               Mark_Accept_Details (Alternative_Tail);
               Mark_Statement_Kind (Analysis, Statement_Accept_Alternative);
            end if;
         end;
      elsif Starts_With_Word (Statement_Line, "then abort") then
         Mark_Statement_Kind (Analysis, Statement_Then_Abort_Alternative);
         declare
            Action : constant String :=
              Tail_After_Leading_Word (Statement_Raw, "then abort");
            Sanitized_Action : constant String :=
              Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Action));
         begin
            if Sanitized_Action'Length /= 0
              and then Sanitized_Action /= ";"
            then
               Mark_Statement_Kind (Analysis, Statement_Then_Abort_Action);
               Mark_Alternative_Action (Action);
            end if;
         end;
      elsif Starts_With_Word (Statement_Line, "terminate") then
         Mark_Statement_Kind (Analysis, Statement_Terminate_Alternative);
      elsif Starts_With_Word (Statement_Line, "declare") then
         Mark_Statement_Kind (Analysis, Statement_Declare_Block);
      elsif Starts_With_Word (Statement_Line, "begin") then
         Mark_Statement_Kind (Analysis, Statement_Begin_Block);
      elsif Starts_With_Word (Statement_Line, "end if") then
         Mark_Statement_Kind (Analysis, Statement_End_If);
      elsif Starts_With_Word (Statement_Line, "end case") and then not In_Record then
         Mark_Statement_Kind (Analysis, Statement_End_Case);
      elsif Starts_With_Word (Statement_Line, "end loop") then
         Mark_Statement_Kind (Analysis, Statement_End_Loop);
         declare
            Tail : constant String :=
              Trim (Tail_After_Leading_Word (Statement_Line, "end loop"));
         begin
            if Tail'Length > 0 and then Tail /= ";" then
               Mark_Statement_Kind (Analysis, Statement_End_Named_Loop);
            end if;
         end;
      elsif Starts_With_Word (Statement_Line, "end select") then
         Mark_Statement_Kind (Analysis, Statement_End_Select);
      elsif Starts_With_Word (Statement_Line, "end return") then
         Mark_Statement_Kind (Analysis, Statement_End_Return);
      elsif Statement_Line = "end;" then
         Mark_Statement_Kind (Analysis, Statement_End_Block);
      elsif Starts_With_Word (Statement_Line, "pragma") then
         Mark_Pragma_Details (Statement_Raw);
      elsif Starts_With_Word (Statement_Line, "return") then
         Mark_Statement_Kind (Analysis, Statement_Return);
         declare
            Return_Tail : constant String :=
              Tail_After_Leading_Word (Statement_Raw, "return");
            Sanitized_Return_Tail : constant String :=
              Editor.Ada_Syntax_Core.Sanitize_Line (Return_Tail);
         begin
            if Ada.Strings.Fixed.Index (Sanitized_Return_Tail, ":") /= 0 then
               Mark_Statement_Kind (Analysis, Statement_Extended_Return);
            elsif Return_Tail /= ";"
              and then Ada.Strings.Fixed.Index (Sanitized_Return_Tail, ":") = 0
            then
               Mark_Statement_Kind (Analysis, Statement_Return_With_Expression);
            end if;
         end;
      elsif Starts_With_Word (Statement_Line, "null") then
         Mark_Statement_Kind (Analysis, Statement_Null);
      elsif Starts_With_Word (Statement_Line, "raise") then
         Mark_Statement_Kind (Analysis, Statement_Raise);
         Mark_Raise_Details (Statement_Raw);
      elsif Starts_With_Word (Statement_Line, "goto") then
         Mark_Statement_Kind (Analysis, Statement_Goto);
         Mark_Goto_Details (Statement_Raw);
      elsif Starts_With_Word (Statement_Line, "exit") then
         Mark_Statement_Kind (Analysis, Statement_Exit);
         Mark_Exit_Details (Statement_Raw);
      elsif Starts_With_Word (Statement_Line, "delay") then
         Mark_Delay_Details (Statement_Raw);
      elsif Starts_With_Word (Statement_Line, "accept") then
         Mark_Accept_Details (Statement_Raw);
      elsif Starts_With_Word (Statement_Line, "requeue") then
         Mark_Statement_Kind (Analysis, Statement_Requeue);
         Mark_Requeue_Target_Details (Statement_Raw);
         if Has_Token (Statement_Raw, "abort") then
            Mark_Statement_Kind (Analysis, Statement_Requeue_With_Abort);
         end if;
      elsif Starts_With_Word (Statement_Line, "abort") then
         Mark_Statement_Kind (Analysis, Statement_Abort);
         Mark_Abort_Target_Details (Statement_Raw);
      elsif Ada.Strings.Fixed.Index (Statement_Raw, ":=") /= 0
        and then Ada.Strings.Fixed.Index (Statement_Raw, ":") =
          Ada.Strings.Fixed.Index (Statement_Raw, ":=")
        and then not Starts_With_Word (Statement_Line, "when")
        and then
          (not Lexical_Helpers.Is_Declaration_Or_Metadata_Line (Statement_Line)
           or else Ada.Strings.Fixed.Index (Statement_Raw, ":") =
             Ada.Strings.Fixed.Index (Statement_Raw, ":="))
      then
         Mark_Statement_Kind (Analysis, Statement_Assignment);
         Mark_Assignment_Target_Details (Statement_Raw);
      elsif Looks_Like_Code_Statement then
         Mark_Statement_Kind (Analysis, Statement_Code);
      elsif Looks_Like_Call_Statement then
         Mark_Statement_Kind (Analysis, Statement_Call);
         if Call_Has_Arguments then
            Mark_Statement_Kind (Analysis, Statement_Call_With_Arguments);
         end if;
         if Call_Has_Named_Association then
            Mark_Statement_Kind (Analysis, Statement_Call_With_Named_Association);
         end if;
         if Call_Has_Selected_Name then
            Mark_Statement_Kind (Analysis, Statement_Call_Selected_Name);
         end if;
         if Call_Has_Access_Dereference then
            Mark_Statement_Kind (Analysis, Statement_Call_Access_Dereference);
         end if;
         if Call_Has_Attribute_Name then
            Mark_Statement_Kind (Analysis, Statement_Call_Attribute_Name);
         end if;
         if Call_Has_Entry_Family_Index then
            Mark_Statement_Kind (Analysis, Statement_Call_Entry_Family_Index);
         end if;
      end if;
   end Mark_Statement_Awareness;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker.Statement_Awareness;
