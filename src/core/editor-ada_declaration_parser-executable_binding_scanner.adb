with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Executable_Binding_Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Line_Dispatch;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Executable_Binding_Scanner is

   use Editor.Ada_Language_Model;
   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Executable_Binding_Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use type Executable_Binding_Kind;
   use type Scope_Id;
   use type Symbol_Id;
   use type Symbol_Kind;

   function Has_Code_Char (Line : String; C : Character) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Code_Char;

   function Has_Declaration_Colon (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Declaration_Colon;

   function Has_Token (Line, Token : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Token;

   function Has_Token_Pair
     (Line, First_Token, Second_Token : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Has_Token_Pair;

   function First_Non_Blank_Column (Line : String) return Positive
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.First_Non_Blank_Column;

   function Strip_Prefixes (Line : String) return String
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Strip_Prefixes;

   function Starts_With_Declaration_Or_Metadata
     (Decl_Lower : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Line_Dispatch.Starts_With_Declaration_Or_Metadata;

   function Normalize_Name (Name : String) return String
     renames Editor.Ada_Language_Model.Normalize_Name;

   function Scope_For_Position
     (Analysis : Analysis_Result;
      Line     : Positive;
      Column   : Positive) return Symbol_Id
     renames Editor.Ada_Language_Model.Scope_For_Position;

   procedure Add_Executable_Binding
     (Analysis        : in out Analysis_Result;
      Kind            : Executable_Binding_Kind;
      Name            : String;
      Expression_Text : String;
      Scope           : Scope_Id;
      Target_Symbol   : Symbol_Id;
      Source_Span     : Source_Range)
     renames Editor.Ada_Language_Model.Add_Executable_Binding;

   procedure Add_Executable_Bindings_From_Text
     (Analysis : in out Analysis_Result;
      Text     : String)
   is
      Line_Start  : Positive := Text'First;
      Line_Number : Positive := 1;
      In_Exception_Part : Boolean := False;
      In_Select_Part    : Boolean := False;

      function Resolve_Local_Target
        (Name : String;
         Line : Positive;
         Column : Positive) return Symbol_Id
      is
         Normalized : constant String := Normalize_Name (Name);
         Owner      : constant Symbol_Id := Scope_For_Position (Analysis, Line, Column);
         Owner_Scope : constant Scope_Id := Scope_Id (Natural (Owner));
      begin
         for I in reverse 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if To_String (S.Normalized_Name) = Normalized
                 and then S.Declaration_Line <= Line
                 and then (S.Enclosing_Scope = Owner_Scope
                           or else S.Enclosing_Scope = Root_Scope
                           or else S.Parent_Symbol = Owner)
               then
                  return S.Id;
               end if;
            end;
         end loop;
         return No_Symbol;
      end Resolve_Local_Target;

      function Is_Executable_Scan_Keyword (Name : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Is_Executable_Scan_Keyword;

      function Is_Executable_Declaration_Line (LWork : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Is_Executable_Declaration_Line;

      procedure Add_Binding
        (Kind : Executable_Binding_Kind;
         Name : String;
         Expr : String;
         Line : Positive;
         Col  : Positive)
      is
         Clean : constant String := Trim (Name);
         Target : constant Symbol_Id := Resolve_Local_Target (Last_Selected_Part (Clean), Line, Col);
         Scope_Owner : constant Symbol_Id := Scope_For_Position (Analysis, Line, Col);
      begin
         if Clean'Length = 0 then
            return;
         end if;

         Add_Executable_Binding
           (Analysis        => Analysis,
            Kind            => Kind,
            Name            => Clean,
            Expression_Text => Expr,
            Scope           => Scope_Id (Natural (Scope_Owner)),
            Target_Symbol   => Target,
            Source_Span           => (Start_Line   => Line,
                                Start_Column => Positive'Max (1, Col),
                                End_Line     => Line,
                                End_Column   => Positive'Max (1, Col + Clean'Length - 1)));
      end Add_Binding;


      function Is_Indexable_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean;
      function Is_Entry_Family_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean;

      function Call_Right_Paren (Expr : String; Open_Pos : Natural) return Natural is
         Depth : Natural := 0;
      begin
         if Open_Pos = 0 or else Open_Pos > Expr'Last then
            return 0;
         end if;

         for I in Open_Pos .. Expr'Last loop
            if Expr (I) = '(' then
               Depth := Depth + 1;
            elsif Expr (I) = ')' then
               if Depth = 0 then
                  return 0;
               end if;
               Depth := Depth - 1;
               if Depth = 0 then
                  return I;
               end if;
            end if;
         end loop;

         return 0;
      end Call_Right_Paren;

      procedure Add_Named_Actuals_In_Call
        (Args : String;
         Line : Positive;
         Base_Column : Positive)
      is
         I     : Natural := Args'First;
         Depth : Natural := 0;
      begin
         --  retain named actual associations from executable calls
         --  as their own semantic binding kind.  This is intentionally
         --  bounded: only top-level Name => associations in the current call
         --  argument list are retained; nested aggregates/calls are handled by
         --  their own expression scans.
         while I <= Args'Last loop
            if Args (I) = '(' then
               Depth := Depth + 1;
               I := I + 1;
            elsif Args (I) = ')' then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
               I := I + 1;
            elsif Depth = 0 and then Is_Name_Start (Args (I)) then
               declare
                  Start : constant Natural := I;
                  Stop  : Natural := I;
                  Arrow : Natural;
               begin
                  while Stop <= Args'Last
                    and then (Is_Name_Char (Args (Stop)) or else Args (Stop) = '.')
                  loop
                     Stop := Stop + 1;
                  end loop;

                  Arrow := Stop;
                  while Arrow <= Args'Last and then Args (Arrow) = ' ' loop
                     Arrow := Arrow + 1;
                  end loop;

                  if Arrow + 1 <= Args'Last
                    and then Args (Arrow) = '='
                    and then Args (Arrow + 1) = '>'
                  then
                     declare
                        Actual_Name : constant String := Args (Start .. Stop - 1);
                        Leaf        : constant String := Last_Selected_Part (Actual_Name);
                     begin
                        if Leaf'Length /= 0
                          and then Lower (Leaf) /= "others"
                          and then not Is_Executable_Scan_Keyword (Leaf)
                        then
                           Add_Binding
                             (Binding_Named_Actual,
                              Actual_Name,
                              Args,
                              Line,
                              Base_Column + Start - Args'First);
                        end if;
                     end;
                  end if;

                  I := Stop;
               end;
            else
               I := I + 1;
            end if;
         end loop;
      end Add_Named_Actuals_In_Call;

      procedure Add_Call_Targets_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         I : Natural := Expr'First;
      begin
         while I <= Expr'Last loop
            if Is_Name_Start (Expr (I)) then
               declare
                  Start : constant Natural := I;
                  Stop  : Natural := I;
                  Next  : Natural;
               begin
                  while Stop <= Expr'Last
                    and then (Is_Name_Char (Expr (Stop)) or else Expr (Stop) = '.')
                  loop
                     Stop := Stop + 1;
                  end loop;

                  Next := Stop;
                  while Next <= Expr'Last and then Expr (Next) = ' ' loop
                     Next := Next + 1;
                  end loop;

                  if Next <= Expr'Last
                    and then Expr (Next) = '('
                    and then (Start = Expr'First or else Expr (Start - 1) /= Character'Val (39))
                  then
                     declare
                        Candidate : constant String := Expr (Start .. Stop - 1);
                        Close     : constant Natural := Call_Right_Paren (Expr, Next);
                     begin
                        if not Is_Executable_Scan_Keyword (Last_Selected_Part (Candidate)) then
                           Add_Binding
                             (Binding_Call_Target,
                              Candidate,
                              Expr,
                              Line,
                              Base_Column + Start - Expr'First);

                           if Close /= 0 and then Next + 1 <= Close - 1 then
                              Add_Named_Actuals_In_Call
                                (Expr (Next + 1 .. Close - 1),
                                 Line,
                                 Base_Column + Next - Expr'First + 1);
                           end if;
                        end if;
                     end;
                  end if;

                  I := Stop;
               end;
            else
               I := I + 1;
            end if;
         end loop;
      end Add_Call_Targets_In_Expression;

      procedure Add_Call_Resolver_Hints_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         I : Natural := Expr'First;

         function Has_Top_Level_Arrow (Args : String) return Boolean is
            Depth : Natural := 0;
            P     : Natural := Args'First;
         begin
            while P <= Args'Last loop
               if Args (P) = '(' then
                  Depth := Depth + 1;
               elsif Args (P) = ')' then
                  if Depth > 0 then
                     Depth := Depth - 1;
                  end if;
               elsif Depth = 0
                 and then P < Args'Last
                 and then Args (P) = '='
                 and then Args (P + 1) = '>'
               then
                  return True;
               end if;
               P := P + 1;
            end loop;

            return False;
         end Has_Top_Level_Arrow;
      begin
         --  retain syntax/model hints for call-shaped ambiguity.
         --  These hints are intentionally resolver-facing metadata only: they
         --  identify selected prefixes, selected operation leaves, indexed
         --  prefixes, and entry-family candidate shapes without choosing an
         --  overload or asserting that an entry exists.
         while I <= Expr'Last loop
            if Is_Name_Start (Expr (I)) then
               declare
                  Start : constant Natural := I;
                  Stop  : Natural := I;
                  Next  : Natural;
                  Has_Dot : Boolean := False;
               begin
                  while Stop <= Expr'Last
                    and then (Is_Name_Char (Expr (Stop)) or else Expr (Stop) = '.')
                  loop
                     if Expr (Stop) = '.' then
                        Has_Dot := True;
                     end if;
                     Stop := Stop + 1;
                  end loop;

                  Next := Stop;
                  while Next <= Expr'Last and then Expr (Next) = ' ' loop
                     Next := Next + 1;
                  end loop;

                  if Next <= Expr'Last
                    and then Expr (Next) = '('
                    and then (Start = Expr'First or else Expr (Start - 1) /= Character'Val (39))
                  then
                     declare
                        Candidate : constant String := Expr (Start .. Stop - 1);
                        Leaf      : constant String := Last_Selected_Part (Candidate);
                        Prefix_Last : Natural := 0;
                        Close     : constant Natural := Call_Right_Paren (Expr, Next);
                     begin
                        if Leaf'Length /= 0
                          and then not Is_Executable_Scan_Keyword (Leaf)
                        then
                           if Has_Dot then
                              for P in reverse Candidate'Range loop
                                 if Candidate (P) = '.' then
                                    Prefix_Last := P - 1;
                                    exit;
                                 end if;
                              end loop;

                              if Prefix_Last >= Candidate'First then
                                 declare
                                    Prefix : constant String := Candidate (Candidate'First .. Prefix_Last);
                                 begin
                                    Add_Binding
                                      (Binding_Call_Selected_Prefix,
                                       Prefix,
                                       Expr,
                                       Line,
                                       Base_Column + Start - Expr'First);
                                    Add_Binding
                                      (Binding_Call_Selected_Operation,
                                       Leaf,
                                       Expr,
                                       Line,
                                       Base_Column + Stop - Leaf'Length - Expr'First);

                                    --  A selected call prefix is also a safe
                                    --  dispatching/entry-call candidate hint;
                                    --  the resolver may later prove it is an
                                    --  ordinary selected procedure call.
                                    Add_Binding
                                      (Binding_Call_Dispatching_Prefix,
                                       Prefix,
                                       Expr,
                                       Line,
                                       Base_Column + Start - Expr'First);
                                 end;
                              end if;
                           else
                              Add_Binding
                                (Binding_Call_Entry_Family_Candidate,
                                 Candidate,
                                 Expr,
                                 Line,
                                 Base_Column + Start - Expr'First);
                           end if;

                           if Is_Entry_Family_Target
                                (Candidate, Line, Base_Column + Start - Expr'First)
                           then
                              Add_Binding
                                (Binding_Call_Entry_Family_Candidate,
                                 Candidate,
                                 Expr,
                                 Line,
                                 Base_Column + Start - Expr'First);
                           elsif Is_Indexable_Target
                                   (Candidate, Line, Base_Column + Start - Expr'First)
                             or else
                               (not Has_Dot
                                and then Close /= 0
                                and then Next + 1 <= Close - 1
                                and then not Has_Top_Level_Arrow
                                  (Expr (Next + 1 .. Close - 1)))
                           then
                              Add_Binding
                                (Binding_Call_Indexed_Prefix,
                                 Candidate,
                                 Expr,
                                 Line,
                                 Base_Column + Start - Expr'First);
                           end if;
                        end if;
                     end;
                  end if;

                  I := Stop;
               end;
            else
               I := I + 1;
            end if;
         end loop;
      end Add_Call_Resolver_Hints_In_Expression;


      procedure Add_Selected_Components_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         I : Natural := Expr'First;
      begin
         while I <= Expr'Last loop
            if Is_Name_Start (Expr (I)) then
               declare
                  Start    : constant Natural := I;
                  Stop     : Natural := I;
                  Next     : Natural;
                  Has_Dot  : Boolean := False;
               begin
                  while Stop <= Expr'Last
                    and then (Is_Name_Char (Expr (Stop)) or else Expr (Stop) = '.')
                  loop
                     if Expr (Stop) = '.' then
                        Has_Dot := True;
                     end if;
                     Stop := Stop + 1;
                  end loop;

                  Next := Stop;
                  while Next <= Expr'Last and then Expr (Next) = ' ' loop
                     Next := Next + 1;
                  end loop;

                  if Has_Dot
                    and then Stop > Start
                    and then Expr (Stop - 1) /= '.'
                    and then (Start = Expr'First or else Expr (Start - 1) /= Character'Val (39))
                    and then (Next > Expr'Last or else Expr (Next) /= '(')
                  then
                     declare
                        Candidate : constant String := Expr (Start .. Stop - 1);
                        Leaf      : constant String := Last_Selected_Part (Candidate);
                     begin
                        if Leaf'Length /= 0
                          and then not Is_Executable_Scan_Keyword (Leaf)
                        then
                           Add_Binding
                             (Binding_Selected_Component,
                              Leaf,
                              Candidate,
                              Line,
                              Base_Column + Stop - Leaf'Length - Expr'First);
                        end if;
                     end;
                  end if;

                  I := Stop;
               end;
            else
               I := I + 1;
            end if;
         end loop;
      end Add_Selected_Components_In_Expression;

      function Symbol_Kind_For_Target (Id : Symbol_Id) return Symbol_Kind is
      begin
         if Id = No_Symbol
           or else Natural (Id) = 0
           or else Natural (Id) > Symbol_Count (Analysis)
         then
            return Symbol_Unknown;
         end if;

         return Symbol_At (Analysis, Positive (Id)).Kind;
      end Symbol_Kind_For_Target;

      function Is_Indexable_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean
      is
         Id : constant Symbol_Id := Resolve_Local_Target (Last_Selected_Part (Name), Line, Col);
         K  : constant Symbol_Kind := Symbol_Kind_For_Target (Id);
      begin
         return K = Symbol_Object
           or else K = Symbol_Constant
           or else K = Symbol_Discriminant
           or else K = Symbol_Record_Component
           or else K = Symbol_Generic_Formal_Object;
      end Is_Indexable_Target;

      function Is_Type_Conversion_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean
      is
         Id : constant Symbol_Id := Resolve_Local_Target (Last_Selected_Part (Name), Line, Col);
         K  : constant Symbol_Kind := Symbol_Kind_For_Target (Id);
      begin
         return K = Symbol_Type
           or else K = Symbol_Subtype
           or else K = Symbol_Record_Type
           or else K = Symbol_Generic_Formal_Type;
      end Is_Type_Conversion_Target;

      function Is_Entry_Family_Target
        (Name : String;
         Line : Positive;
         Col  : Positive) return Boolean
      is
         Id : constant Symbol_Id := Resolve_Local_Target (Last_Selected_Part (Name), Line, Col);
         K  : constant Symbol_Kind := Symbol_Kind_For_Target (Id);
         Leaf : constant String := Normalize_Name (Last_Selected_Part (Name));
      begin
         --  an entry-family call has the same surface shape as an
         --  indexed object name: Entry_Name (Index).  When the prefix resolves
         --  to a retained entry declaration, preserve the parenthesized index
         --  as tasking metadata instead of array-index metadata.
         if K = Symbol_Entry then
            return True;
         end if;

         for I in reverse 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if S.Kind = Symbol_Entry
                 and then To_String (S.Normalized_Name) = Leaf
                 and then S.Declaration_Line <= Line
               then
                  return True;
               end if;
            end;
         end loop;

         return False;
      end Is_Entry_Family_Target;

      function Contains_Range_Dots (Expr : String) return Boolean
        renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers
          .Contains_Range_Dots;

      function Is_Executable_Pragma_Name (Name : String) return Boolean is
         L : constant String := Lower (Name);
      begin
         return L = "assert"
           or else L = "assert_and_cut"
           or else L = "loop_invariant"
           or else L = "loop_variant"
           or else L = "precondition"
           or else L = "postcondition"
           or else L = "type_invariant"
           or else L = "predicate"
           or else L = "invariant";
      end Is_Executable_Pragma_Name;

      function Is_Executable_Aspect_Name (Name : String) return Boolean is
         L : constant String := Lower (Name);
      begin
         --  contract/assertion-like aspects contain executable
         --  expressions even though they live on declaration lines.
         return L = "pre"
           or else L = "post"
           or else L = "pre'class"
           or else L = "post'class"
           or else L = "type_invariant"
           or else L = "type_invariant'class"
           or else L = "dynamic_predicate"
           or else L = "static_predicate"
           or else L = "predicate"
           or else L = "default_initial_condition"
           or else L = "initial_condition";
      end Is_Executable_Aspect_Name;

      procedure Add_Range_Bounds_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         Dot_Pos : constant Natural := Ada.Strings.Fixed.Index (Expr, "..");

         procedure Add_Bound (Part : String; Part_Offset : Natural) is
            Bound_Name : constant String := Leading_Name (Trim (Part));
         begin
            if Bound_Name'Length /= 0
              and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Bound_Name))
            then
               declare
                  Local_Pos : constant Natural := Ada.Strings.Fixed.Index (Part, Bound_Name);
               begin
                  Add_Binding
                    (Binding_Range_Bound,
                     Bound_Name,
                     Expr,
                     Line,
                     Base_Column + Part_Offset + Local_Pos - Part'First);
               end;
            end if;
         end Add_Bound;
      begin
         if Dot_Pos = 0 then
            return;
         end if;

         if Dot_Pos > Expr'First then
            Add_Bound (Expr (Expr'First .. Dot_Pos - 1), 0);
         end if;

         if Dot_Pos + 2 <= Expr'Last then
            Add_Bound
              (Expr (Dot_Pos + 2 .. Expr'Last),
               Dot_Pos + 1 - Expr'First);
         end if;
      end Add_Range_Bounds_In_Expression;

      function Matching_Right_Paren (Expr : String; Open_Pos : Natural) return Natural is
         Depth : Natural := 0;
      begin
         if Open_Pos = 0 or else Open_Pos > Expr'Last then
            return 0;
         end if;

         for I in Open_Pos .. Expr'Last loop
            if Expr (I) = '(' then
               Depth := Depth + 1;
            elsif Expr (I) = ')' then
               if Depth = 0 then
                  return 0;
               end if;
               Depth := Depth - 1;
               if Depth = 0 then
                  return I;
               end if;
            end if;
         end loop;

         return 0;
      end Matching_Right_Paren;


      procedure Add_Quantified_Bindings_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         Low : constant String := Lower (Expr);
         Search_From : Natural := Low'First;

         function Next_Quantifier (From_Pos : Natural; Pattern_Length : out Natural) return Natural is
            All_Pos  : Natural := 0;
            Some_Pos : Natural := 0;
         begin
            Pattern_Length := 0;
            if From_Pos <= Low'Last then
               All_Pos := Ada.Strings.Fixed.Index (Low (From_Pos .. Low'Last), "for all ");
               Some_Pos := Ada.Strings.Fixed.Index (Low (From_Pos .. Low'Last), "for some ");
            end if;

            if All_Pos = 0 then
               if Some_Pos /= 0 then
                  Pattern_Length := 9;
               end if;
               return Some_Pos;
            elsif Some_Pos = 0 or else All_Pos < Some_Pos then
               Pattern_Length := 8;
               return All_Pos;
            else
               Pattern_Length := 9;
               return Some_Pos;
            end if;
         end Next_Quantifier;
      begin
         --  retain quantified-expression local names without
         --  treating the expression as a full compiler AST.  This covers
         --  "for all I in Source_Span => ..." and "for some Item of Items => ..."
         --  in executable expressions and assertion pragmas.  Unknown
         --  quantified domains still degrade through No_Symbol rather than
         --  being guessed.
         while Search_From <= Low'Last loop
            declare
               Pattern_Length : Natural := 0;
               Q_Pos : constant Natural := Next_Quantifier (Search_From, Pattern_Length);
            begin
               exit when Q_Pos = 0;

               declare
                  Param_Start : Natural := Q_Pos + Pattern_Length;
               begin
                  while Param_Start <= Expr'Last and then Expr (Param_Start) = ' ' loop
                     Param_Start := Param_Start + 1;
                  end loop;

                  if Param_Start <= Expr'Last and then Is_Name_Start (Expr (Param_Start)) then
                     declare
                        Param_Stop : Natural := Param_Start;
                     begin
                        while Param_Stop <= Expr'Last and then Is_Name_Char (Expr (Param_Stop)) loop
                           Param_Stop := Param_Stop + 1;
                        end loop;

                        declare
                           Param_Name : constant String := Expr (Param_Start .. Param_Stop - 1);
                           After_Param : Natural := Param_Stop;
                        begin
                           Add_Binding
                             (Binding_Quantified_Parameter,
                              Param_Name,
                              Expr,
                              Line,
                              Base_Column + Param_Start - Expr'First);

                           while After_Param <= Expr'Last and then Expr (After_Param) = ' ' loop
                              After_Param := After_Param + 1;
                           end loop;

                           if After_Param + 1 <= Low'Last
                             and then (Starts_With_Word (Low (After_Param .. Low'Last), "in")
                                       or else Starts_With_Word (Low (After_Param .. Low'Last), "of"))
                           then
                              declare
                                 Keyword_Len : constant Natural :=
                                   (if Starts_With_Word (Low (After_Param .. Low'Last), "in") then 2 else 2);
                                 Domain_Start : Natural := After_Param + Keyword_Len;
                                 Domain_End   : Natural := Expr'Last;
                                 Arrow_Pos    : constant Natural :=
                                   (if Domain_Start <= Expr'Last then
                                       Ada.Strings.Fixed.Index (Expr (Domain_Start .. Expr'Last), "=>")
                                    else
                                       0);
                              begin
                                 while Domain_Start <= Expr'Last and then Expr (Domain_Start) = ' ' loop
                                    Domain_Start := Domain_Start + 1;
                                 end loop;

                                 if Arrow_Pos /= 0 then
                                    Domain_End := Arrow_Pos - 1;
                                 end if;

                                 if Domain_Start <= Domain_End then
                                    declare
                                       Domain_Text : constant String := Trim (Expr (Domain_Start .. Domain_End));
                                       Domain_Name : constant String := Leading_Name (Domain_Text);
                                    begin
                                       if Domain_Name'Length /= 0
                                         and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Domain_Name))
                                       then
                                          Add_Binding
                                            (Binding_Quantified_Source,
                                             Domain_Name,
                                             Domain_Text,
                                             Line,
                                             Base_Column + Domain_Start - Expr'First +
                                               Ada.Strings.Fixed.Index (Domain_Text, Domain_Name) - Domain_Text'First);
                                       end if;
                                    end;
                                 end if;
                              end;
                           end if;
                        end;
                     end;
                  end if;
               end;

               Search_From := Q_Pos + Pattern_Length;
            end;
         end loop;
      end Add_Quantified_Bindings_In_Expression;

      procedure Add_Conditional_Expression_Bindings_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         LExpr : constant String := Lower (Expr);
         Search_From : Natural := LExpr'First;
      begin
         --  retain bounded Ada conditional-expression metadata.
         --  This is intentionally expression-shape retention rather than a
         --  full expression AST: simple leading names from the condition and
         --  both result branches are enough for safe semantic colouring and
         --  navigation while unresolved/complex expressions still degrade.
         while Search_From <= LExpr'Last loop
            declare
               If_Pos : Natural := 0;
            begin
               for I in Search_From .. LExpr'Last loop
                  if Lexical_Helpers.Starts_At_Word (LExpr, I, "if") then
                     If_Pos := I;
                     exit;
                  end if;
               end loop;

               exit when If_Pos = 0;

               declare
                  Then_Pos : Natural := 0;
                  Else_Pos : Natural := 0;
               begin
                  for I in If_Pos + 2 .. LExpr'Last loop
                     if Lexical_Helpers.Starts_At_Word (LExpr, I, "then") then
                        Then_Pos := I;
                        exit;
                     end if;
                  end loop;

                  if Then_Pos /= 0 then
                     for I in Then_Pos + 4 .. LExpr'Last loop
                        if Lexical_Helpers.Starts_At_Word (LExpr, I, "else") then
                           Else_Pos := I;
                           exit;
                        end if;
                     end loop;
                  end if;

                  if Then_Pos /= 0
                    and then Else_Pos /= 0
                    and then If_Pos + 2 <= Then_Pos - 1
                    and then Then_Pos + 4 <= Else_Pos - 1
                  then
                     declare
                        Condition_Text : constant String := Trim (Expr (If_Pos + 2 .. Then_Pos - 1));
                        Condition_Name : constant String := Leading_Name (Condition_Text);
                     begin
                        if Condition_Name'Length /= 0
                          and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Condition_Name))
                        then
                           Add_Binding
                             (Binding_Conditional_Expression_Condition,
                              Condition_Name,
                              Condition_Text,
                              Line,
                              Base_Column + If_Pos + 1 - Expr'First +
                                Ada.Strings.Fixed.Index (Condition_Text, Condition_Name) - Condition_Text'First);
                        end if;
                     end;

                     declare
                        Then_Text : constant String := Trim (Expr (Then_Pos + 4 .. Else_Pos - 1));
                        Then_Name : constant String := Leading_Name (Then_Text);
                     begin
                        if Then_Name'Length /= 0
                          and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Then_Name))
                        then
                           Add_Binding
                             (Binding_Conditional_Expression_Branch,
                              Then_Name,
                              Then_Text,
                              Line,
                              Base_Column + Then_Pos + 3 - Expr'First +
                                Ada.Strings.Fixed.Index (Then_Text, Then_Name) - Then_Text'First);
                        end if;
                     end;

                     declare
                        Else_Text : constant String := Trim (Expr (Else_Pos + 4 .. Expr'Last));
                        Else_Name : constant String := Leading_Name (Else_Text);
                     begin
                        if Else_Name'Length /= 0
                          and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Else_Name))
                        then
                           Add_Binding
                             (Binding_Conditional_Expression_Branch,
                              Else_Name,
                              Else_Text,
                              Line,
                              Base_Column + Else_Pos + 3 - Expr'First +
                                Ada.Strings.Fixed.Index (Else_Text, Else_Name) - Else_Text'First);
                        end if;
                     end;
                  end if;

                  Search_From := If_Pos + 2;
               end;
            end;
         end loop;
      end Add_Conditional_Expression_Bindings_In_Expression;


      procedure Add_Raise_Expression_Bindings_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         LExpr : constant String := Lower (Expr);
         Search_From : Natural := LExpr'First;

         function Is_Statement_Raise (Pos : Natural) return Boolean is
         begin
            if Pos = LExpr'First then
               return True;
            end if;

            for J in LExpr'First .. Pos - 1 loop
               if LExpr (J) /= ' ' then
                  return False;
               end if;
            end loop;
            return True;
         end Is_Statement_Raise;
      begin
         --  retain raise-expression exception targets separately
         --  from statement-level raise targets.  This remains a bounded
         --  expression scan: ``raise E`` only contributes metadata when it is
         --  embedded in another expression, and unresolved targets degrade
         --  through No_Symbol instead of being guessed.
         while Search_From <= LExpr'Last loop
            declare
               Raise_Pos : Natural := 0;
            begin
               for I in Search_From .. LExpr'Last loop
                  if Lexical_Helpers.Starts_At_Word (LExpr, I, "raise") then
                     Raise_Pos := I;
                     exit;
                  end if;
               end loop;

               exit when Raise_Pos = 0;

               if not Is_Statement_Raise (Raise_Pos) then
                  declare
                     Name_Start : Natural := Raise_Pos + 5;
                  begin
                     while Name_Start <= Expr'Last and then Expr (Name_Start) = ' ' loop
                        Name_Start := Name_Start + 1;
                     end loop;

                     if Name_Start <= Expr'Last and then Is_Name_Start (Expr (Name_Start)) then
                        declare
                           Name_Stop : Natural := Name_Start;
                        begin
                           while Name_Stop <= Expr'Last
                             and then (Is_Name_Char (Expr (Name_Stop)) or else Expr (Name_Stop) = '.')
                           loop
                              Name_Stop := Name_Stop + 1;
                           end loop;

                           declare
                              Target_Name : constant String := Expr (Name_Start .. Name_Stop - 1);
                           begin
                              if not Is_Executable_Scan_Keyword (Last_Selected_Part (Target_Name)) then
                                 Add_Binding
                                   (Binding_Raise_Expression_Target,
                                    Target_Name,
                                    Expr,
                                    Line,
                                    Base_Column + Name_Start - Expr'First);
                              end if;
                           end;
                        end;
                     end if;
                  end;
               end if;

               Search_From := Raise_Pos + 5;
            end;
         end loop;
      end Add_Raise_Expression_Bindings_In_Expression;

      procedure Add_Delta_Aggregate_Bindings_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         LExpr : constant String := Lower (Expr);
         Search_From : Natural := LExpr'First;
      begin
         --  retain Ada 2022 delta aggregate base/component names
         --  as executable expression bindings.  This stays deliberately
         --  syntactic: it records the base leading name before "with delta"
         --  and top-level component associations after it, without attempting
         --  GNAT-equivalent aggregate legality or record-type expansion.
         loop
            exit when Search_From > LExpr'Last;
            declare
               With_Pos : constant Natural :=
                 Ada.Strings.Fixed.Index (LExpr (Search_From .. LExpr'Last), "with delta");
            begin
               exit when With_Pos = 0;

               if With_Pos > Expr'First then
                  declare
                     Base_Start : Natural := Expr'First;
                  begin
                     --  The scanner may receive a whole assignment statement,
                     --  not only the parenthesized delta aggregate expression.
                     --  Use the last syntactic opener/assignment marker before
                     --  "with delta" so "X := (Base with delta ...)" records
                     --  Base, not X.
                     for J in Expr'First .. With_Pos - 1 loop
                        if Expr (J) = '(' or else Expr (J) = '=' then
                           Base_Start := J + 1;
                        end if;
                     end loop;

                     declare
                        Base_Text : constant String := Trim (Expr (Base_Start .. With_Pos - 1));
                        Base_Name : constant String := Leading_Name (Base_Text);
                     begin
                        if Base_Name'Length /= 0
                          and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Base_Name))
                        then
                           declare
                              Local_Pos : constant Natural := Ada.Strings.Fixed.Index (Base_Text, Base_Name);
                           begin
                              Add_Binding
                                (Binding_Delta_Aggregate_Base,
                                 Base_Name,
                                 Expr,
                                 Line,
                                 Base_Column + Base_Start - Expr'First + Local_Pos - Base_Text'First);
                           end;
                        end if;
                     end;
                  end;
               end if;

               declare
                  Assocs_Start : constant Natural := With_Pos + 10;
                  I            : Natural := Assocs_Start;
                  Depth        : Natural := 0;
               begin
                  while I <= Expr'Last loop
                     if Expr (I) = '(' then
                        Depth := Depth + 1;
                        I := I + 1;
                     elsif Expr (I) = ')' then
                        if Depth = 0 then
                           exit;
                        end if;
                        Depth := Depth - 1;
                        I := I + 1;
                     elsif Depth = 0 and then Is_Name_Start (Expr (I)) then
                        declare
                           Start : constant Natural := I;
                           Stop  : Natural := I;
                           Arrow : Natural;
                        begin
                           while Stop <= Expr'Last
                             and then (Is_Name_Char (Expr (Stop)) or else Expr (Stop) = '.')
                           loop
                              Stop := Stop + 1;
                           end loop;

                           Arrow := Stop;
                           while Arrow <= Expr'Last and then Expr (Arrow) = ' ' loop
                              Arrow := Arrow + 1;
                           end loop;

                           if Arrow + 1 <= Expr'Last
                             and then Expr (Arrow) = '='
                             and then Expr (Arrow + 1) = '>'
                           then
                              declare
                                 Component_Name : constant String := Expr (Start .. Stop - 1);
                                 Leaf           : constant String := Last_Selected_Part (Component_Name);
                              begin
                                 if Leaf'Length /= 0
                                   and then Lower (Leaf) /= "others"
                                   and then not Is_Executable_Scan_Keyword (Leaf)
                                 then
                                    Add_Binding
                                      (Binding_Delta_Aggregate_Component,
                                       Component_Name,
                                       Expr,
                                       Line,
                                       Base_Column + Start - Expr'First);
                                 end if;
                              end;
                           end if;

                           I := Stop;
                        end;
                     else
                        I := I + 1;
                     end if;
                  end loop;
               end;

               Search_From := With_Pos + 10;
            end;
         end loop;
      end Add_Delta_Aggregate_Bindings_In_Expression;


      procedure Add_Case_Expression_Bindings_In_Expression
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         LExpr : constant String := Lower (Expr);
         Search_From : Natural := LExpr'First;
      begin
         --  retain bounded Ada case-expression selector/choice
         --  metadata.  This intentionally does not build a full expression AST;
         --  it records only leading names from simple case expressions so
         --  semantic colouring/navigation can distinguish them from statement
         --  case alternatives and ordinary calls.
         while Search_From <= LExpr'Last loop
            declare
               Case_Pos : Natural := 0;
            begin
               for I in Search_From .. LExpr'Last loop
                  if Lexical_Helpers.Starts_At_Word (LExpr, I, "case") then
                     Case_Pos := I;
                     exit;
                  end if;
               end loop;

               exit when Case_Pos = 0;

               declare
                  Is_Pos : Natural := 0;
               begin
                  for I in Case_Pos + 4 .. LExpr'Last loop
                     if Lexical_Helpers.Starts_At_Word (LExpr, I, "is") then
                        Is_Pos := I;
                        exit;
                     end if;
                  end loop;

                  if Is_Pos /= 0 and then Case_Pos + 4 <= Is_Pos - 1 then
                     declare
                        Selector_Text : constant String := Trim (Expr (Case_Pos + 4 .. Is_Pos - 1));
                        Selector_Name : constant String := Leading_Name (Selector_Text);
                     begin
                        if Selector_Name'Length /= 0
                          and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Selector_Name))
                        then
                           Add_Binding
                             (Binding_Case_Expression_Selector,
                              Selector_Name,
                              Selector_Text,
                              Line,
                              Base_Column + Case_Pos + 3 - Expr'First +
                                Ada.Strings.Fixed.Index (Selector_Text, Selector_Name) - Selector_Text'First);
                        end if;
                     end;

                     declare
                        Pos : Natural := Is_Pos + 2;
                     begin
                        while Pos <= LExpr'Last loop
                           declare
                              When_Pos : Natural := 0;
                           begin
                              for J in Pos .. LExpr'Last loop
                                 if Lexical_Helpers.Starts_At_Word (LExpr, J, "when") then
                                    When_Pos := J;
                                    exit;
                                 end if;
                              end loop;

                              exit when When_Pos = 0;

                              declare
                                 Arrow : constant Natural := Ada.Strings.Fixed.Index
                                   (Source => Expr,
                                    Pattern => "=>",
                                    From => When_Pos + 4);
                              begin
                                 exit when Arrow = 0;

                                 declare
                                    Choice_Text : constant String := Trim (Expr (When_Pos + 4 .. Arrow - 1));
                                    Choice_Name : constant String := Leading_Name (Choice_Text);
                                 begin
                                    if Choice_Name'Length /= 0
                                      and then Lower (Choice_Name) /= "others"
                                      and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Choice_Name))
                                    then
                                       Add_Binding
                                         (Binding_Case_Expression_Choice,
                                          Choice_Name,
                                          Choice_Text,
                                          Line,
                                          Base_Column + When_Pos + 3 - Expr'First +
                                            Ada.Strings.Fixed.Index (Choice_Text, Choice_Name) - Choice_Text'First);
                                    end if;
                                 end;

                                 Pos := Arrow + 2;
                              end;
                           end;
                        end loop;
                     end;
                  end if;

                  Search_From := Case_Pos + 4;
               end;
            end;
         end loop;
      end Add_Case_Expression_Bindings_In_Expression;

      procedure Add_Deep_Expression_Name_Bindings
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         I : Natural := Expr'First;
      begin
         --  retain additional expression/name binding shapes that
         --  are useful for IDE semantic colouring and navigation but still
         --  bounded and conservative: array indexing/slicing, explicit
         --  dereference, allocators, named aggregate associations, and
         --  qualified-expression targets.
         while I <= Expr'Last loop
            if Is_Name_Start (Expr (I)) then
               declare
                  Start : constant Natural := I;
                  Stop  : Natural := I;
                  Next  : Natural;
               begin
                  while Stop <= Expr'Last
                    and then (Is_Name_Char (Expr (Stop)) or else Expr (Stop) = '.')
                  loop
                     Stop := Stop + 1;
                  end loop;

                  Next := Stop;
                  while Next <= Expr'Last and then Expr (Next) = ' ' loop
                     Next := Next + 1;
                  end loop;

                  declare
                     Candidate : constant String := Expr (Start .. Stop - 1);
                     Leaf      : constant String := Last_Selected_Part (Candidate);
                  begin
                     if Leaf'Length /= 0
                       and then not Is_Executable_Scan_Keyword (Leaf)
                     then
                        if Lower (Leaf) = "all" then
                           declare
                              Dot : Natural := 0;
                           begin
                              for J in reverse Candidate'Range loop
                                 if Candidate (J) = '.' then
                                    Dot := J;
                                    exit;
                                 end if;
                              end loop;

                              if Dot > Candidate'First then
                                 Add_Binding
                                   (Binding_Dereference,
                                    Candidate (Candidate'First .. Dot - 1),
                                    Candidate,
                                    Line,
                                    Base_Column + Start - Expr'First);
                              end if;
                           end;
                        end if;

                        if Next <= Expr'Last
                          and then Expr (Next) = '('
                          and then Is_Entry_Family_Target
                            (Candidate, Line, Base_Column + Start - Expr'First)
                        then
                           declare
                              Close : constant Natural := Matching_Right_Paren (Expr, Next);
                           begin
                              if Close /= 0 then
                                 Add_Binding
                                   (Binding_Entry_Family_Index,
                                    Candidate,
                                    Expr (Start .. Close),
                                    Line,
                                    Base_Column + Start - Expr'First);
                              end if;
                           end;
                        elsif Next <= Expr'Last
                          and then Expr (Next) = '('
                          and then Is_Indexable_Target
                            (Candidate, Line, Base_Column + Start - Expr'First)
                        then
                           declare
                              Close : constant Natural := Matching_Right_Paren (Expr, Next);
                           begin
                              if Close /= 0 then
                                 Add_Binding
                                   ((if Contains_Range_Dots (Expr (Next + 1 .. Close - 1))
                                     then Binding_Array_Slice
                                     else Binding_Array_Index),
                                    Candidate,
                                    Expr (Start .. Close),
                                    Line,
                                    Base_Column + Start - Expr'First);

                                 if Contains_Range_Dots (Expr (Next + 1 .. Close - 1)) then
                                    Add_Range_Bounds_In_Expression
                                      (Expr (Next + 1 .. Close - 1),
                                       Line,
                                       Base_Column + Next - Expr'First + 1);
                                 end if;
                              end if;
                           end;
                        elsif Next <= Expr'Last
                          and then Expr (Next) = '('
                          and then Is_Type_Conversion_Target
                            (Candidate, Line, Base_Column + Start - Expr'First)
                        then
                           declare
                              Close : constant Natural := Matching_Right_Paren (Expr, Next);
                           begin
                              if Close /= 0 then
                                 --  retain explicit type-conversion
                                 --  targets separately from call targets and
                                 --  index/slice prefixes.  This is deliberately
                                 --  conservative: the prefix must resolve to a
                                 --  retained type-like symbol in the current
                                 --  analysis, so ordinary calls are not
                                 --  reclassified as conversions.
                                 Add_Binding
                                   (Binding_Type_Conversion_Target,
                                    Candidate,
                                    Expr (Start .. Close),
                                    Line,
                                    Base_Column + Start - Expr'First);
                              end if;
                           end;
                        end if;

                        if Next + 3 <= Expr'Last
                          and then Lower (Expr (Next .. Next + 3)) = ".all"
                        then
                           Add_Binding
                             (Binding_Dereference,
                              Candidate,
                              Expr (Start .. Next + 3),
                              Line,
                              Base_Column + Start - Expr'First);
                        end if;

                        if Next <= Expr'Last
                          and then Expr (Next) = Character'Val (39)
                          and then Next + 1 <= Expr'Last
                          and then Expr (Next + 1) = '('
                        then
                           Add_Binding
                             (Binding_Qualified_Expression_Target,
                              Candidate,
                              Expr (Start .. Expr'Last),
                              Line,
                              Base_Column + Start - Expr'First);
                        elsif Next <= Expr'Last
                          and then Expr (Next) = Character'Val (39)
                          and then Next + 1 <= Expr'Last
                          and then Is_Name_Start (Expr (Next + 1))
                        then
                           declare
                              Attr_Start : constant Natural := Next + 1;
                              Attr_Stop  : Natural := Attr_Start;
                           begin
                              while Attr_Stop <= Expr'Last
                                and then Is_Name_Char (Expr (Attr_Stop))
                              loop
                                 Attr_Stop := Attr_Stop + 1;
                              end loop;

                              --  retain attribute prefixes as
                              --  executable name bindings.  This makes
                              --  Obj'Length, T'Size, and T'Image (...)
                              --  navigable/colourable by the prefix symbol
                              --  without confusing qualified expressions
                              --  T'(...) with attributes.
                              Add_Binding
                                (Binding_Attribute_Prefix,
                                 Candidate,
                                 Expr (Start .. Attr_Stop - 1),
                                 Line,
                                 Base_Column + Start - Expr'First);
                           end;
                        end if;

                        if Next + 1 <= Expr'Last
                          and then Expr (Next) = '='
                          and then Expr (Next + 1) = '>'
                          and then Leaf /= "others"
                        then
                           declare
                              Has_Open_Paren : Boolean := False;
                           begin
                              if Start > Expr'First then
                                 for J in Expr'First .. Start - 1 loop
                                    if Expr (J) = '(' then
                                       Has_Open_Paren := True;
                                    end if;
                                 end loop;
                              end if;

                              if Has_Open_Paren then
                                 Add_Binding
                                   (Binding_Aggregate_Component_Selector,
                                    Candidate,
                                    Expr,
                                    Line,
                                    Base_Column + Start - Expr'First);
                                 Add_Binding
                                   (Binding_Aggregate_Component,
                                    Candidate,
                                    Expr,
                                    Line,
                                    Base_Column + Start - Expr'First);
                              end if;
                           end;
                        end if;
                     end if;

                     if Lower (Leaf) = "new" then
                        declare
                           T_Start : Natural := Next;
                        begin
                           while T_Start <= Expr'Last and then Expr (T_Start) = ' ' loop
                              T_Start := T_Start + 1;
                           end loop;

                           if T_Start <= Expr'Last and then Is_Name_Start (Expr (T_Start)) then
                              declare
                                 T_Stop : Natural := T_Start;
                              begin
                                 while T_Stop <= Expr'Last
                                   and then (Is_Name_Char (Expr (T_Stop)) or else Expr (T_Stop) = '.')
                                 loop
                                    T_Stop := T_Stop + 1;
                                 end loop;

                                 Add_Binding
                                   (Binding_Allocator,
                                    Expr (T_Start .. T_Stop - 1),
                                    Expr,
                                    Line,
                                    Base_Column + T_Start - Expr'First);
                              end;
                           end if;
                        end;
                     end if;
                  end;

                  I := Stop;
               end;
            else
               I := I + 1;
            end if;
         end loop;
      end Add_Deep_Expression_Name_Bindings;

      procedure Add_Aspect_Expression_Bindings
        (Expr : String;
         Line : Positive;
         Base_Column : Positive)
      is
         I : Natural := Expr'First;
      begin
         while I <= Expr'Last loop
            if Is_Name_Start (Expr (I)) then
               declare
                  Aspect_Start : constant Natural := I;
                  Aspect_Stop  : Natural := I;
                  Arrow        : Natural;
               begin
                  while Aspect_Stop <= Expr'Last
                    and then (Is_Name_Char (Expr (Aspect_Stop))
                              or else Expr (Aspect_Stop) = Character'Val (39))
                  loop
                     Aspect_Stop := Aspect_Stop + 1;
                  end loop;

                  Arrow := Aspect_Stop;
                  while Arrow <= Expr'Last and then Expr (Arrow) = ' ' loop
                     Arrow := Arrow + 1;
                  end loop;

                  if Arrow + 1 <= Expr'Last
                    and then Expr (Arrow) = '='
                    and then Expr (Arrow + 1) = '>'
                  then
                     declare
                        Aspect_Name : constant String := Expr (Aspect_Start .. Aspect_Stop - 1);
                     begin
                        if Is_Executable_Aspect_Name (Aspect_Name) then
                           declare
                              Value_Start : Natural := Arrow + 2;
                              Value_Stop  : Natural := Value_Start;
                              Depth       : Natural := 0;
                           begin
                              while Value_Start <= Expr'Last and then Expr (Value_Start) = ' ' loop
                                 Value_Start := Value_Start + 1;
                              end loop;

                              Value_Stop := Value_Start;
                              while Value_Stop <= Expr'Last loop
                                 if Expr (Value_Stop) = '(' then
                                    Depth := Depth + 1;
                                 elsif Expr (Value_Stop) = ')' then
                                    if Depth > 0 then
                                       Depth := Depth - 1;
                                    end if;
                                 elsif Depth = 0
                                   and then (Expr (Value_Stop) = ','
                                             or else Expr (Value_Stop) = ';')
                                 then
                                    exit;
                                 end if;
                                 Value_Stop := Value_Stop + 1;
                              end loop;

                              if Value_Start <= Value_Stop - 1 then
                                 declare
                                    Value_Expr : constant String := Trim (Expr (Value_Start .. Value_Stop - 1));
                                    Name       : constant String := Leading_Name (Value_Expr);
                                 begin
                                    if Name'Length /= 0
                                      and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
                                    then
                                       declare
                                          Name_Pos : constant Natural := Ada.Strings.Fixed.Index (Value_Expr, Name);
                                       begin
                                          Add_Binding
                                            (Binding_Aspect_Expression,
                                             Name,
                                             Value_Expr,
                                             Line,
                                             Base_Column + Value_Start - Expr'First + Name_Pos - Value_Expr'First);
                                       end;
                                    end if;

                                    Add_Call_Targets_In_Expression
                                      (Value_Expr, Line, Base_Column + Value_Start - Expr'First);
                                    Add_Selected_Components_In_Expression
                                      (Value_Expr, Line, Base_Column + Value_Start - Expr'First);
                                    Add_Deep_Expression_Name_Bindings
                                      (Value_Expr, Line, Base_Column + Value_Start - Expr'First);
                                    Add_Conditional_Expression_Bindings_In_Expression
                                      (Value_Expr, Line, Base_Column + Value_Start - Expr'First);
                                    Add_Raise_Expression_Bindings_In_Expression
                                      (Value_Expr, Line, Base_Column + Value_Start - Expr'First);
                                 end;
                              end if;
                           end;
                        end if;
                     end;

                     I := Arrow + 2;
                  else
                     I := Aspect_Stop;
                  end if;
               end;
            else
               I := I + 1;
            end if;
         end loop;
      end Add_Aspect_Expression_Bindings;

      procedure Add_Pragma_Named_Argument_Bindings
        (Args : String;
         Line : Positive;
         Base_Column : Positive)
      is
         I     : Natural := Args'First;
         Depth : Natural := 0;
      begin
         while I <= Args'Last loop
            if Args (I) = '(' then
               Depth := Depth + 1;
               I := I + 1;
            elsif Args (I) = ')' then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
               I := I + 1;
            elsif Depth = 0 and then Is_Name_Start (Args (I)) then
               declare
                  Name_Start : constant Natural := I;
                  Name_Stop  : Natural := I;
                  Arrow      : Natural;
               begin
                  while Name_Stop <= Args'Last
                    and then (Is_Name_Char (Args (Name_Stop))
                              or else Args (Name_Stop) = '.')
                  loop
                     Name_Stop := Name_Stop + 1;
                  end loop;

                  Arrow := Name_Stop;
                  while Arrow <= Args'Last and then Args (Arrow) = ' ' loop
                     Arrow := Arrow + 1;
                  end loop;

                  if Arrow + 1 <= Args'Last
                    and then Args (Arrow) = '='
                    and then Args (Arrow + 1) = '>'
                  then
                     declare
                        Arg_Name : constant String := Args (Name_Start .. Name_Stop - 1);
                     begin
                        if Arg_Name'Length /= 0
                          and then not Is_Executable_Scan_Keyword
                            (Last_Selected_Part (Arg_Name))
                        then
                           Add_Binding
                             (Binding_Pragma_Argument,
                              Arg_Name,
                              Args,
                              Line,
                              Base_Column + Name_Start - Args'First);
                        end if;
                     end;
                  end if;

                  I := Name_Stop;
               end;
            else
               I := I + 1;
            end if;
         end loop;
      end Add_Pragma_Named_Argument_Bindings;

      procedure Add_Pragma_Expression_Argument_Bindings
        (Args : String;
         Line : Positive;
         Base_Column : Positive)
      is
         Start : Natural := Args'First;
         I     : Natural := Args'First;
         Depth : Natural := 0;

         procedure Add_Segment (First, Last : Natural) is
         begin
            if First > Last then
               return;
            end if;

            declare
               Segment : constant String := Trim (Args (First .. Last));
               Name    : constant String := Leading_Name (Segment);
            begin
               if Name'Length /= 0
                 and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
               then
                  declare
                     Name_Pos : constant Natural := Ada.Strings.Fixed.Index (Segment, Name);
                  begin
                     Add_Binding
                       (Binding_Pragma_Argument,
                        Name,
                        Segment,
                        Line,
                        Base_Column + First - Args'First + Name_Pos - Segment'First);
                  end;
               end if;
            end;
         end Add_Segment;
      begin
         while I <= Args'Last loop
            if Args (I) = '(' then
               Depth := Depth + 1;
            elsif Args (I) = ')' then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Args (I) = ',' and then Depth = 0 then
               Add_Segment (Start, I - 1);
               Start := I + 1;
            end if;

            I := I + 1;
         end loop;

         if Start <= Args'Last then
            Add_Segment (Start, Args'Last);
         end if;
      end Add_Pragma_Expression_Argument_Bindings;

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

         if not Is_Executable_Declaration_Line (LWork) then
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
           and then not Is_Executable_Declaration_Line (LWork)
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
                          and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                       and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                                and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Param))
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
                             and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Param))
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
                       and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                       and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                       and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                       and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                       and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                 and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                 and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                 and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                 and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Name))
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
                       and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Source_Name))
                     then
                        Add_Binding
                          (Binding_Iteration_Source,
                           Source_Name,
                           Work,
                           Line,
                           Ada.Strings.Fixed.Index (Work, Source_Name));
                     end if;

                     if Filter_Name'Length /= 0
                       and then not Is_Executable_Scan_Keyword (Last_Selected_Part (Filter_Name))
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
                             and then not Is_Executable_Scan_Keyword
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
            if not Is_Executable_Declaration_Line (LWork) then
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
           and then not Is_Executable_Declaration_Line (LWork)
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
   begin
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
   end Add_Executable_Bindings_From_Text;

end Editor.Ada_Declaration_Parser.Executable_Binding_Scanner;
