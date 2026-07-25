separate (Editor.Ada_Declaration_Parser.Executable_Binding_Scanner.Text_Scan)
package body Text_Scan_Phase is

   use Binding_Publication;
   use Candidate_Classification;

   In_Exception_Part : Boolean := False;
   In_Select_Part    : Boolean := False;

      procedure Scan_Line (Raw : String; Line : Positive) is
         Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw);
         Low  : constant String := Lower (Code);
         Work : constant String := Trim (Code);
         LWork : constant String := Trim (Low);
      begin
         if Work'Length = 0 then
            return;
         end if;

         declare
            With_Pos : constant Natural := Ada.Strings.Fixed.Index (Low, " with ");
         begin
            if With_Pos /= 0
              and then not Starts_With_Word (LWork, "with")
            then
               Add_Aspect_Expression_Bindings
                 (Work (With_Pos + 6 .. Work'Last), Line, With_Pos + 6);
            end if;
         end;

         if Starts_With_Word (LWork, "with") then
            declare
               Tail_Start : Natural := Work'First + 4;
            begin
               while Tail_Start <= Work'Last and then Work (Tail_Start) = ' ' loop
                  Tail_Start := Tail_Start + 1;
               end loop;

               if Tail_Start <= Work'Last then
                  Add_Aspect_Expression_Bindings
                    (Work (Tail_Start .. Work'Last), Line, Tail_Start);
               end if;
            end;
         else
            declare
               Name  : constant String := Leading_Name (Work);
               Arrow : Natural := 0;
            begin
               if Name'Length /= 0
                 and then Is_Executable_Aspect_Name (Name)
               then
                  Arrow := Ada.Strings.Fixed.Index (Work, "=>");
                  if Arrow /= 0 then
                     Add_Aspect_Expression_Bindings (Work, Line, Work'First);
                  end if;
               end if;
            end;
         end if;

         if not Candidate_Classification.Is_Executable_Declaration_Line (LWork) then
            Add_Quantified_Bindings_In_Expression (Work, Line, 1);
         end if;

         --  Statement labels and goto targets are executable navigation
         --  bindings.  They are not declarations in the normal outline sense,
         --  but IDE navigation can present them safely within the same
         --  snapshot.
         declare
            Open : Natural := Ada.Strings.Fixed.Index (Work, "<<");
         begin
            while Open /= 0 loop
               declare
                  Close_Pos : constant Natural := Ada.Strings.Fixed.Index (Work (Open + 2 .. Work'Last), ">>");
               begin
                  exit when Close_Pos = 0;
                  declare
                     Label_Name : constant String := Trim (Work (Open + 2 .. Close_Pos - 1));
                  begin
                     Add_Binding (Binding_Label_Declaration, Label_Name, Label_Name, Line, Open + 2);
                     if Close_Pos + 2 > Work'Last then
                        exit;
                     end if;
                     Open := Ada.Strings.Fixed.Index (Work (Close_Pos + 2 .. Work'Last), "<<");
                  end;
               end;
            end loop;
         end;

         if Starts_With_Word (LWork, "goto") then
            declare
               Name : constant String := Leading_Name (Trim (Work (Work'First + 4 .. Work'Last)));
            begin
               Add_Binding (Binding_Goto_Target, Name, Work, Line, Ada.Strings.Fixed.Index (Work, Name));
            end;
         end if;

         --  retain named statement/block labels that are written in
         --  Ada's prefix-label form (for example Main_Loop : loop, Worker :
         --  declare, and Region : begin).  These are distinct from <<Label>>
         --  declarations and allow same-snapshot navigation from exit targets
         --  without treating arbitrary object declarations as block labels.
         declare
            Colon : constant Natural := Ada.Strings.Fixed.Index (Work, ":");
         begin
            if Colon /= 0
              and then Ada.Strings.Fixed.Index (Work, ":=") = 0
              and then Colon > Work'First
            then
               declare
                  Label_Name : constant String := Trim (Work (Work'First .. Colon - 1));
                  Tail       : constant String := Trim (Work (Colon + 1 .. Work'Last));
                  LTail      : constant String := Lower (Tail);
               begin
                  if Label_Name'Length /= 0
                    and then Ada.Strings.Fixed.Index (Label_Name, " ") = 0
                    and then Is_Name_Start (Label_Name (Label_Name'First))
                    and then (Starts_With_Word (LTail, "loop")
                              or else Starts_With_Word (LTail, "declare")
                              or else Starts_With_Word (LTail, "begin")
                              or else Starts_With_Word (LTail, "for")
                              or else Starts_With_Word (LTail, "while"))
                  then
                     Add_Binding
                       (Binding_Block_Label,
                        Label_Name,
                        Work,
                        Line,
                        Ada.Strings.Fixed.Index (Work, Label_Name));
                  end if;
               end;
            end if;
         end;

         --  retain each top-level named argument in executable
         --  assertion pragmas.  Pragmas such as Assert and Loop_Invariant can
         --  contain executable Boolean expressions, while representation/import
         --  pragmas should not create statement-level semantic bindings.
         if Starts_With_Word (LWork, "pragma") then
            declare
               Tail : constant String := Trim (Work (Work'First + 6 .. Work'Last));
               Pragma_Name : constant String := Leading_Name (Tail);
            begin
               if Pragma_Name'Length /= 0
                 and then Is_Executable_Pragma_Name (Pragma_Name)
               then
                  declare
                     Open_Pos : constant Natural := Ada.Strings.Fixed.Index (Tail, "(");
                  begin
                     if Open_Pos /= 0 then
                        declare
                           Close_Pos : constant Natural := Matching_Right_Paren (Tail, Open_Pos);
                        begin
                           if Close_Pos /= 0 and then Open_Pos + 1 <= Close_Pos - 1 then
                              declare
                                 Args : constant String := Tail (Open_Pos + 1 .. Close_Pos - 1);
                                 Args_Col : constant Natural := Ada.Strings.Fixed.Index (Work, Args);
                              begin
                                 Add_Pragma_Named_Argument_Bindings
                                   (Args, Line, Args_Col);
                                 Add_Pragma_Expression_Argument_Bindings
                                   (Args, Line, Args_Col);

                                 Add_Call_Targets_In_Expression
                                   (Args, Line, Args_Col);
                                 Add_Selected_Components_In_Expression
                                   (Args, Line, Args_Col);
                                 Add_Deep_Expression_Name_Bindings
                                   (Args, Line, Args_Col);
                              end;
                           end if;
                        end;
                     end if;
                  end;
               end if;
            end;
         end if;

         --  retain executable transfer/tasking name targets
         --  that are neither declarations nor ordinary calls.  These are
         --  useful for same-snapshot navigation/colouring while remaining
         --  conservative: only the syntactic target name is retained and
         --  unresolved targets degrade through No_Symbol.
         --  retain return-statement expression targets and
         --  extended-return object declarations as executable bindings.
         --  This makes return-specific names navigable/colourable without
         --  treating function specifications (which also contain the word
         --  return) as executable statements.
         if Starts_With_Word (LWork, "return")
           and then not Candidate_Classification.Is_Executable_Declaration_Line (LWork)
         then
            declare
               Tail : constant String := Trim (Work (Work'First + 6 .. Work'Last));
               Colon : constant Natural := Ada.Strings.Fixed.Index (Tail, ":");
               Semi  : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
            begin
               if Tail'Length /= 0 then
                  if Colon /= 0
                    and then (Semi = 0 or else Colon < Semi)
                  then
                     declare
                        Obj : constant String := Trim (Tail (Tail'First .. Colon - 1));
                     begin
                        if Obj'Length /= 0
                          and then Ada.Strings.Fixed.Index (Obj, " ") = 0
                          and then Is_Name_Start (Obj (Obj'First))
                        then
                           Add_Binding
                             (Binding_Return_Object,
                              Obj,
                              Work,
                              Line,
                              Ada.Strings.Fixed.Index (Work, Obj));
                        end if;
                     end;
                  else
                     declare
                        Name : constant String := Leading_Name (Tail);
                     begin
                        if Name'Length /= 0
                          and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
                        then
                           Add_Binding
                             (Binding_Return_Target,
                              Name,
                              Work,
                              Line,
                              Ada.Strings.Fixed.Index (Work, Name));
                        end if;
                     end;
                  end if;
               end if;
            end;
         end if;

         if Starts_With_Word (LWork, "delay") then
            declare
               Tail : constant String := Trim (Work (Work'First + 5 .. Work'Last));
            begin
               if Tail'Length /= 0 then
                  declare
                     Effective_Tail : constant String :=
                       (if Starts_With_Word (Lower (Tail), "until") then
                           Trim (Tail (Tail'First + 5 .. Tail'Last))
                        else
                           Tail);
                     Name : constant String := Leading_Name (Effective_Tail);
                  begin
                     if Name'Length /= 0
                       and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
                     then
                        Add_Binding
                          (Binding_Delay_Target,
                           Name,
                           Work,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Name));
                     end if;
                  end;
               end if;
            end;
         end if;

         if Starts_With_Word (LWork, "abort") then
            declare
               Tail : constant String := Trim (Work (Work'First + 5 .. Work'Last));
               Start : Natural := Tail'First;
            begin
               for I in Tail'Range loop
                  if Tail (I) = ',' or else Tail (I) = ';' then
                     declare
                        Name : constant String := Leading_Name (Trim (Tail (Start .. I - 1)));
                     begin
                        if Name'Length /= 0 then
                           Add_Binding
                             (Binding_Abort_Target,
                              Name,
                              Work,
                              Line,
                              Ada.Strings.Fixed.Index (Work, Name));
                        end if;
                     end;
                     Start := I + 1;
                  end if;
               end loop;
               if Start <= Tail'Last then
                  declare
                     Name : constant String := Leading_Name (Trim (Tail (Start .. Tail'Last)));
                  begin
                     if Name'Length /= 0 then
                        Add_Binding
                          (Binding_Abort_Target,
                           Name,
                           Work,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Name));
                     end if;
                  end;
               end if;
            end;
         end if;

         if Starts_With_Word (LWork, "raise") then
            declare
               Tail : constant String := Trim (Work (Work'First + 5 .. Work'Last));
               Name : constant String := Leading_Name (Tail);
            begin
               if Name'Length /= 0 then
                  Add_Binding
                    (Binding_Raise_Target,
                     Name,
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (Work, Name));
               end if;
            end;
         end if;

         if Starts_With_Word (LWork, "requeue") then
            declare
               Tail : constant String := Trim (Work (Work'First + 7 .. Work'Last));
               Name : constant String := Leading_Name (Tail);
            begin
               if Name'Length /= 0 then
                  Add_Binding
                    (Binding_Requeue_Target,
                     Name,
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (Work, Name));
               end if;
            end;
         end if;

         if Starts_With_Word (LWork, "exit") then
            declare
               Tail : constant String := Trim (Work (Work'First + 5 .. Work'Last));
               Name : constant String := Leading_Name (Tail);
            begin
               if Name'Length /= 0
                 and then Lower (Name) /= "when"
               then
                  Add_Binding
                    (Binding_Exit_Target,
                     Name,
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (Work, Name));
               end if;
            end;
         end if;

         if Starts_With_Word (LWork, "accept") then
            declare
               Tail : constant String := Trim (Work (Work'First + 7 .. Work'Last));
               Name : constant String := Leading_Name (Tail);

               procedure Add_Accept_Parameter_Names (Segment : String) is
                  Colon : constant Natural := Ada.Strings.Fixed.Index (Segment, ":");
                  Start : Natural;
               begin
                  if Colon = 0 then
                     return;
                  end if;

                  declare
                     Names_Text : constant String := Trim (Segment (Segment'First .. Colon - 1));
                  begin
                     if Names_Text'Length = 0 then
                        return;
                     end if;

                     Start := Names_Text'First;
                     for I in Names_Text'Range loop
                        if Names_Text (I) = ',' then
                           declare
                              Param : constant String := Leading_Name (Trim (Names_Text (Start .. I - 1)));
                           begin
                              if Param'Length /= 0
                                and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Param))
                              then
                                 Add_Binding
                                   (Binding_Accept_Parameter,
                                    Param,
                                    Work,
                                    Line,
                                    Ada.Strings.Fixed.Index (Work, Param));
                              end if;
                           end;
                           Start := I + 1;
                        end if;
                     end loop;

                     if Start <= Names_Text'Last then
                        declare
                           Param : constant String := Leading_Name (Trim (Names_Text (Start .. Names_Text'Last)));
                        begin
                           if Param'Length /= 0
                             and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Param))
                           then
                              Add_Binding
                                (Binding_Accept_Parameter,
                                 Param,
                                 Work,
                                 Line,
                                 Ada.Strings.Fixed.Index (Work, Param));
                           end if;
                        end;
                     end if;
                  end;
               end Add_Accept_Parameter_Names;
            begin
               if Name'Length /= 0 then
                  Add_Binding
                    (Binding_Accept_Entry,
                     Name,
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (Work, Name));
               end if;

               --  accept statement formals are executable local
               --  names, not declaration-outline rows.  Retain them as
               --  bounded statement bindings so colouring/navigation can
               --  treat names in the accept body like local values without
               --  constructing a full tasking semantic model.
               declare
                  Open_Pos  : constant Natural := Ada.Strings.Fixed.Index (Tail, "(");
                  Close_Pos : constant Natural :=
                    (if Open_Pos /= 0 then Call_Right_Paren (Tail, Open_Pos) else 0);
               begin
                  if Open_Pos /= 0
                    and then Close_Pos /= 0
                    and then Close_Pos > Open_Pos + 1
                  then
                     declare
                        Params : constant String := Tail (Open_Pos + 1 .. Close_Pos - 1);
                        Start  : Natural := Params'First;
                     begin
                        for I in Params'Range loop
                           if Params (I) = ';' then
                              Add_Accept_Parameter_Names (Params (Start .. I - 1));
                              Start := I + 1;
                           end if;
                        end loop;

                        if Start <= Params'Last then
                           Add_Accept_Parameter_Names (Params (Start .. Params'Last));
                        end if;
                     end;
                  end if;
               end;
            end;
         end if;

         --  retain entry barrier expression names from protected
         --  body entry declarations such as "entry Start when Ready is".
         --  The entry itself remains declaration metadata; the barrier name is
         --  executable expression metadata for semantic/navigation consumers.
         if Starts_With_Word (LWork, "entry") then
            declare
               When_Pos : constant Natural := Ada.Strings.Fixed.Index (LWork, " when ");
            begin
               if When_Pos /= 0 then
                  declare
                     Tail : constant String := Trim (Work (When_Pos + 6 .. Work'Last));
                     LTail : constant String := Lower (Tail);
                     Is_Pos : constant Natural := Ada.Strings.Fixed.Index (LTail, " is");
                     Barrier : constant String :=
                       (if Is_Pos /= 0 then Trim (Tail (Tail'First .. Is_Pos - 1)) else Tail);
                     Effective_Barrier : constant String :=
                       (if Starts_With_Word (Lower (Barrier), "not") then
                           Trim (Barrier (Barrier'First + 3 .. Barrier'Last))
                        else
                           Barrier);
                     Name : constant String := Leading_Name (Effective_Barrier);
                  begin
                     if Name'Length /= 0
                       and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
                     then
                        Add_Binding
                          (Binding_Entry_Barrier,
                           Name,
                           Work,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Name));
                     end if;
                  end;
               end if;
            end;
         end if;

         --  retain bounded select-statement navigation
         --  bindings.  A select guard such as "when Ready =>" is not a
         --  case alternative or an exception choice, and a selective entry
         --  call such as "select Start;" / "or Start;" should be kept as
         --  an executable target without treating the keywords select/or as
         --  callable names.
         if Starts_With_Word (LWork, "select") then
            In_Select_Part := True;
            declare
               Tail : constant String := Trim (Work (Work'First + 6 .. Work'Last));
            begin
               if Starts_With_Word (Lower (Tail), "terminate") then
                  Add_Binding
                    (Binding_Select_Terminate,
                     "terminate",
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (LWork, "terminate"));
               elsif Starts_With_Word (Lower (Tail), "delay") then
                  declare
                     After_Delay : constant String := Trim (Tail (Tail'First + 5 .. Tail'Last));
                     Effective_Tail : constant String :=
                       (if Starts_With_Word (Lower (After_Delay), "until") then
                           Trim (After_Delay (After_Delay'First + 5 .. After_Delay'Last))
                        else
                           After_Delay);
                     Name : constant String := Leading_Name (Effective_Tail);
                  begin
                     if Name'Length /= 0
                       and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
                     then
                        Add_Binding
                          (Binding_Select_Delay_Target,
                           Name,
                           Work,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Name));
                     end if;
                  end;
               else
                  declare
                     Name : constant String := Leading_Name (Tail);
                  begin
                     if Name'Length /= 0
                       and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
                     then
                        Add_Binding
                          (Binding_Select_Entry_Call,
                           Name,
                           Work,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Name));
                     end if;
                  end;
               end if;
            end;
         elsif In_Select_Part and then Starts_With_Word (LWork, "or") then
            declare
               Tail : constant String := Trim (Work (Work'First + 2 .. Work'Last));
            begin
               if Starts_With_Word (Lower (Tail), "terminate") then
                  Add_Binding
                    (Binding_Select_Terminate,
                     "terminate",
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (LWork, "terminate"));
               elsif Starts_With_Word (Lower (Tail), "delay") then
                  declare
                     After_Delay : constant String := Trim (Tail (Tail'First + 5 .. Tail'Last));
                     Effective_Tail : constant String :=
                       (if Starts_With_Word (Lower (After_Delay), "until") then
                           Trim (After_Delay (After_Delay'First + 5 .. After_Delay'Last))
                        else
                           After_Delay);
                     Name : constant String := Leading_Name (Effective_Tail);
                  begin
                     if Name'Length /= 0
                       and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
                     then
                        Add_Binding
                          (Binding_Select_Delay_Target,
                           Name,
                           Work,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Name));
                     end if;
                  end;
               else
                  declare
                     Name : constant String := Leading_Name (Tail);
                  begin
                     if Name'Length /= 0
                       and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
                     then
                        Add_Binding
                          (Binding_Select_Entry_Call,
                           Name,
                           Work,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Name));
                     end if;
                  end;
               end if;
            end;
         end if;

         if In_Select_Part and then Starts_With_Word (LWork, "terminate") then
            Add_Binding
              (Binding_Select_Terminate,
               "terminate",
               Work,
               Line,
               Ada.Strings.Fixed.Index (LWork, "terminate"));
         end if;

         --  retain asynchronous select abort alternatives.
         --  ``then abort`` is a select-structure marker, not a callable name
         --  and not an ordinary ``then`` keyword line.  Keep it as bounded
         --  executable metadata so tasking-aware navigation/colouring can
         --  distinguish asynchronous select abortable parts without guessing
         --  a target symbol.
         if In_Select_Part
           and then Starts_With_Word (LWork, "then")
         then
            declare
               Tail : constant String := Trim (Work (Work'First + 4 .. Work'Last));
            begin
               if Starts_With_Word (Lower (Tail), "abort") then
                  Add_Binding
                    (Binding_Select_Abort,
                     "then abort",
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (LWork, "then"));
               end if;
            end;
         end if;

         --  retain simple executable condition/selector names
         --  used by if/elsif/while/case statements.  This complements call,
         --  component, and deep expression bindings without building a full
         --  expression AST: only a leading resolvable expression name is kept,
         --  and unresolved names continue to degrade through No_Symbol.
         if Starts_With_Word (LWork, "if") then
            declare
               Tail : constant String := Trim (Work (Work'First + 2 .. Work'Last));
               Then_Pos : constant Natural := Ada.Strings.Fixed.Index (Lower (Tail), " then");
               Condition : constant String :=
                 (if Then_Pos /= 0 then Trim (Tail (Tail'First .. Then_Pos - 1)) else Tail);
               Name : constant String := Leading_Name (Condition);
            begin
               if Name'Length /= 0
                 and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
               then
                  Add_Binding
                    (Binding_Condition_Target,
                     Name,
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (Work, Name));
               end if;
            end;
         elsif Starts_With_Word (LWork, "elsif") then
            declare
               Tail : constant String := Trim (Work (Work'First + 5 .. Work'Last));
               Then_Pos : constant Natural := Ada.Strings.Fixed.Index (Lower (Tail), " then");
               Condition : constant String :=
                 (if Then_Pos /= 0 then Trim (Tail (Tail'First .. Then_Pos - 1)) else Tail);
               Name : constant String := Leading_Name (Condition);
            begin
               if Name'Length /= 0
                 and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
               then
                  Add_Binding
                    (Binding_Condition_Target,
                     Name,
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (Work, Name));
               end if;
            end;
         elsif Starts_With_Word (LWork, "while") then
            declare
               Tail : constant String := Trim (Work (Work'First + 5 .. Work'Last));
               Loop_Pos : constant Natural := Ada.Strings.Fixed.Index (Lower (Tail), " loop");
               Condition : constant String :=
                 (if Loop_Pos /= 0 then Trim (Tail (Tail'First .. Loop_Pos - 1)) else Tail);
               Name : constant String := Leading_Name (Condition);
            begin
               if Name'Length /= 0
                 and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
               then
                  Add_Binding
                    (Binding_Condition_Target,
                     Name,
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (Work, Name));
               end if;
            end;
         elsif Starts_With_Word (LWork, "case") then
            declare
               Tail : constant String := Trim (Work (Work'First + 4 .. Work'Last));
               Is_Pos : constant Natural := Ada.Strings.Fixed.Index (Lower (Tail), " is");
               Selector : constant String :=
                 (if Is_Pos /= 0 then Trim (Tail (Tail'First .. Is_Pos - 1)) else Tail);
               Name : constant String := Leading_Name (Selector);
            begin
               if Name'Length /= 0
                 and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
               then
                  Add_Binding
                    (Binding_Condition_Target,
                     Name,
                     Work,
                     Line,
                     Ada.Strings.Fixed.Index (Work, Name));
               end if;
            end;
         end if;

         if Starts_With_Word (LWork, "for") then
            declare
               Tail : constant String := Trim (Work (Work'First + 3 .. Work'Last));
               In_Pos : Natural := Ada.Strings.Fixed.Index (Lower (Tail), " in ");
               Of_Pos : Natural := Ada.Strings.Fixed.Index (Lower (Tail), " of ");
               Loop_Pos : Natural := Ada.Strings.Fixed.Index (Lower (Tail), " loop");
               Stop : Natural := 0;
               Source_Start : Natural := 0;
            begin
               if In_Pos /= 0 then
                  Stop := In_Pos - 1;
                  Source_Start := In_Pos + 4;
               elsif Of_Pos /= 0 then
                  Stop := Of_Pos - 1;
                  Source_Start := Of_Pos + 4;
               end if;
               if Stop > 0 then
                  declare
                     Param : constant String := Trim (Tail (Tail'First .. Stop));
                  begin
                     Add_Binding (Binding_Loop_Parameter, Param, Work, Line, Ada.Strings.Fixed.Index (Work, Param));
                  end;
               end if;
               if Source_Start /= 0 and then Source_Start <= Tail'Last then
                  declare
                     Source_End : constant Natural :=
                       (if Loop_Pos /= 0 and then Loop_Pos > Source_Start then Loop_Pos - 1 else Tail'Last);
                     Raw_Source_Expr : constant String := Trim (Tail (Source_Start .. Source_End));
                     When_Pos : constant Natural := Ada.Strings.Fixed.Index (Lower (Raw_Source_Expr), " when ");
                     Source_Expr : constant String :=
                       (if When_Pos /= 0 then
                           Trim (Raw_Source_Expr (Raw_Source_Expr'First .. When_Pos - 1))
                        else
                           Raw_Source_Expr);
                     Filter_Expr : constant String :=
                       (if When_Pos /= 0 and then When_Pos + 6 <= Raw_Source_Expr'Last then
                           Trim (Raw_Source_Expr (When_Pos + 6 .. Raw_Source_Expr'Last))
                        else
                           "");
                     Source_Name : constant String := Leading_Name (Source_Expr);
                     Filter_Name : constant String := Leading_Name (Filter_Expr);
                  begin
                     if Source_Name'Length /= 0
                       and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Source_Name))
                     then
                        Add_Binding
                          (Binding_Iteration_Source,
                           Source_Name,
                           Work,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Source_Name));
                     end if;

                     if Filter_Name'Length /= 0
                       and then not Candidate_Classification.Is_Executable_Scan_Keyword (Last_Selected_Part (Filter_Name))
                     then
                        Add_Binding
                          (Binding_Iteration_Filter,
                           Filter_Name,
                           Work,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Filter_Name));
                     end if;

                     if Contains_Range_Dots (Source_Expr) then
                        Add_Range_Bounds_In_Expression
                          (Source_Expr,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Source_Expr));
                     end if;
                  end;
               end if;
            end;
         end if;

         if Starts_With_Word (LWork, "exception") then
            In_Exception_Part := True;
         elsif Starts_With_Word (LWork, "end") then
            In_Exception_Part := False;
            if Ada.Strings.Fixed.Index (LWork, "select") /= 0 then
               In_Select_Part := False;
            end if;
         end if;

         if Starts_With_Word (LWork, "when") then
            declare
               Arrow : constant Natural := Ada.Strings.Fixed.Index (Work, "=>");
               Binding_Kind : constant Executable_Binding_Kind :=
                 (if In_Exception_Part then
                     Binding_Exception_Handler_Choice
                  elsif In_Select_Part then
                     Binding_Select_Guard
                  else
                     Binding_Case_Choice);
            begin
               if Arrow /= 0 then
                  declare
                     Raw_Choices : constant String := Trim (Work (Work'First + 4 .. Arrow - 1));
                     Colon       : constant Natural := Ada.Strings.Fixed.Index (Raw_Choices, ":");
                     Choices     : constant String :=
                       (if In_Exception_Part
                         and then Colon /= 0
                         and then Colon < Raw_Choices'Last then
                           Trim (Raw_Choices (Colon + 1 .. Raw_Choices'Last))
                        else Raw_Choices);
                     Start : Natural := Choices'First;
                  begin
                     --  retain the optional exception occurrence
                     --  identifier in handlers such as
                     --  ``when Occ : Constraint_Error =>`` as a local
                     --  executable binding distinct from the exception choice.
                     if In_Exception_Part
                       and then Colon /= 0
                       and then Colon > Raw_Choices'First
                     then
                        declare
                           Occurrence : constant String :=
                             Trim (Raw_Choices (Raw_Choices'First .. Colon - 1));
                        begin
                           if Occurrence'Length /= 0
                             and then Ada.Strings.Fixed.Index (Occurrence, "|") = 0
                             and then not Candidate_Classification.Is_Executable_Scan_Keyword
                               (Last_Selected_Part (Occurrence))
                           then
                              Add_Binding
                                (Binding_Exception_Occurrence,
                                 Occurrence,
                                 Work,
                                 Line,
                                 Ada.Strings.Fixed.Index (Work, Occurrence));
                           end if;
                        end;
                     end if;

                     for I in Choices'Range loop
                        if Choices (I) = '|' then
                           declare
                              Choice : constant String := Trim (Choices (Start .. I - 1));
                           begin
                              if Choice /= "others" then
                                 Add_Binding (Binding_Kind, Choice, Work, Line, Ada.Strings.Fixed.Index (Work, Choice));
                              end if;
                           end;
                           Start := I + 1;
                        end if;
                     end loop;
                     if Start <= Choices'Last then
                        declare
                           Choice : constant String := Trim (Choices (Start .. Choices'Last));
                        begin
                           if Choice /= "others" then
                              Add_Binding (Binding_Kind, Choice, Work, Line, Ada.Strings.Fixed.Index (Work, Choice));
                           end if;
                        end;
                     end if;
                  end;
               end if;
            end;
         end if;

         --  /377: retain call targets and selected component uses
         --  that appear inside executable expressions, not only standalone
         --  call statements or assignment targets.  This covers conditions,
         --  return expressions, assignments, nested actuals, and component
         --  reads while still skipping declaration/visibility lines and Ada
         --  attributes such as Integer'Image.
         declare
            Assign : constant Natural := Ada.Strings.Fixed.Index (Work, ":=");
         begin
            if not Candidate_Classification.Is_Executable_Declaration_Line (LWork) then
               Add_Call_Targets_In_Expression (Work, Line, Work'First);
               Add_Call_Resolver_Hints_In_Expression (Work, Line, Work'First);
               if Assign /= 0 and then Assign + 2 <= Work'Last then
                  Add_Selected_Components_In_Expression
                    (Work (Assign + 2 .. Work'Last), Line, Work'First + Assign + 1);
               else
                  Add_Selected_Components_In_Expression (Work, Line, Work'First);
               end if;
               Add_Deep_Expression_Name_Bindings (Work, Line, Work'First);
               Add_Conditional_Expression_Bindings_In_Expression (Work, Line, Work'First);
               Add_Raise_Expression_Bindings_In_Expression (Work, Line, Work'First);
               Add_Delta_Aggregate_Bindings_In_Expression (Work, Line, Work'First);
               Add_Case_Expression_Bindings_In_Expression (Work, Line, Work'First);
            end if;

            if Assign /= 0 then
               declare
                  Target : constant String := Trim (Work (Work'First .. Assign - 1));
               begin
                  if Target'Length /= 0 and then Ada.Strings.Fixed.Index (Target, ":") = 0 then
                     Add_Binding (Binding_Assignment_Target, Target, Work, Line, Ada.Strings.Fixed.Index (Work, Target));
                     if Ada.Strings.Fixed.Index (Target, ".") /= 0 then
                        Add_Binding (Binding_Selected_Component, Last_Selected_Part (Target), Target, Line, Ada.Strings.Fixed.Index (Work, Last_Selected_Part (Target)));
                     end if;
                  end if;
               end;
            end if;
         end;

         if Has_Declaration_Colon (Work)
           and then Ada.Strings.Fixed.Index (Work, ";") /= 0
           and then not Candidate_Classification.Is_Executable_Declaration_Line (LWork)
        then
            declare
               Colon : constant Natural := Ada.Strings.Fixed.Index (Work, ":");
               Names : constant String := Trim (Work (Work'First .. Colon - 1));
               Start : Natural := Names'First;
            begin
               for I in Names'Range loop
                  if Names (I) = ',' then
                     Add_Binding (Binding_Declare_Object, Trim (Names (Start .. I - 1)), Work, Line, Ada.Strings.Fixed.Index (Work, Trim (Names (Start .. I - 1))));
                     Start := I + 1;
                  end if;
               end loop;
               if Start <= Names'Last then
                  Add_Binding (Binding_Declare_Object, Trim (Names (Start .. Names'Last)), Work, Line, Ada.Strings.Fixed.Index (Work, Trim (Names (Start .. Names'Last))));
               end if;
            end;
         end if;

         if not Starts_With_Word (LWork, "if")
           and then not Starts_With_Word (LWork, "for")
           and then not Starts_With_Word (LWork, "while")
           and then not Starts_With_Word (LWork, "case")
           and then not Starts_With_Word (LWork, "return")
           and then not Starts_With_Word (LWork, "raise")
           and then not Starts_With_Word (LWork, "delay")
           and then not Starts_With_Word (LWork, "abort")
           and then not Starts_With_Word (LWork, "select")
           and then not Starts_With_Word (LWork, "or")
           and then not Starts_With_Word (LWork, "then")
           and then not Starts_With_Word (LWork, "when")
           and then not Starts_With_Word (LWork, "pragma")
           and then Ada.Strings.Fixed.Index (Work, ":=") = 0
         then
            declare
               Name : constant String := Leading_Name (Work);
               Semi : constant Natural := Ada.Strings.Fixed.Index (Work, ";");
            begin
               if Name'Length /= 0 and then Semi /= 0 then
                  Add_Binding (Binding_Call_Target, Name, Work, Line, Ada.Strings.Fixed.Index (Work, Name));
               end if;
            end;
         end if;
      end Scan_Line;

      procedure Scan_Text (Text : String) is
         Line_Start  : Positive := Text'First;
         Line_Number : Positive := 1;
      begin
         In_Exception_Part := False;
         In_Select_Part := False;

         if Text'Length = 0 then
         return;
      end if;

      for I in Text'Range loop
         if Text (I) = Ada.Characters.Latin_1.LF then
            declare
               Line_End : Natural := I - 1;
            begin
               if Line_End >= Line_Start and then Text (Line_End) = Ada.Characters.Latin_1.CR then
                  Line_End := Line_End - 1;
               end if;
               if Line_End >= Line_Start then
                  Scan_Line (Text (Line_Start .. Line_End), Line_Number);
               end if;
            end;
            if I < Text'Last then
               Line_Start := I + 1;
            end if;
            Line_Number := Line_Number + 1;
         end if;
      end loop;

      if Line_Start <= Text'Last then
         Scan_Line (Text (Line_Start .. Text'Last), Line_Number);
      end if;
      end Scan_Text;

end Text_Scan_Phase;
