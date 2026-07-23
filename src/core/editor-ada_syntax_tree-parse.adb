with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Token_Cursor;
with Editor.Text_Helpers;


separate (Editor.Ada_Syntax_Tree)
   function Parse (Text : String) return Tree_Type is
      Tree        : Tree_Type;
      Root_Node   : Node_Id;
      Line_Start  : Positive := Text'First;
      Line_Number : Positive := 1;
      Max_Depth   : constant Positive := 256;
      Scope_Stack : array (Positive range 1 .. Max_Depth) of Node_Id := (others => No_Node);
      Scope_Depth : Natural := 0;
      Last_Significant_Node : Node_Id := No_Node;

      function Current_Parent return Node_Id is
      begin
         if Scope_Depth = 0 then
            return Root_Node;
         end if;
         return Scope_Stack (Scope_Depth);
      end Current_Parent;

      function Current_Kind return Node_Kind is
      begin
         if Scope_Depth = 0 then
            return Node_Compilation_Unit;
         end if;
         return Node (Tree, Scope_Stack (Scope_Depth)).Kind;
      end Current_Kind;

      procedure Push_Scope (Id : Node_Id) is
      begin
         if Scope_Depth < Max_Depth then
            Scope_Depth := Scope_Depth + 1;
            Scope_Stack (Scope_Depth) := Id;
         end if;
      end Push_Scope;

      procedure Pop_Scope is
      begin
         if Scope_Depth > 0 then
            Scope_Stack (Scope_Depth) := No_Node;
            Scope_Depth := Scope_Depth - 1;
         end if;
      end Pop_Scope;

      procedure Pop_Alternative_Scope is
      begin
         while Scope_Depth > 0
           and then Is_Alternative_Node (Current_Kind)
         loop
            Pop_Scope;
         end loop;
      end Pop_Alternative_Scope;

      procedure Pop_Exception_Handler_Scope is
      begin
         while Scope_Depth > 0
           and then Current_Kind = Node_Exception_Handler
         loop
            Pop_Scope;
         end loop;
      end Pop_Exception_Handler_Scope;

      procedure Add_Recovery_Node
        (Kind   : Node_Kind;
         Parent : Node_Id;
         Depth  : Natural;
         Line   : Positive;
         Label  : String)
      is
         Ignored : Node_Id;
      begin
         Ignored := Add_Node
           (Tree, Kind, (Line, 1, Line, Last_Column_For (Label)),
            Parent, Depth, Label);
      end Add_Recovery_Node;

      function Matching_End_Depth (End_Code : String) return Natural is
         Target : constant String := End_Target_Text (End_Code);
      begin
         for D in reverse 1 .. Scope_Depth loop
            declare
               Candidate : constant Node_Kind := Node (Tree, Scope_Stack (D)).Kind;
            begin
               if Target /= ""
                 and then Is_Transient_Statement_Part (Candidate)
               then
                  null;
               elsif End_Matches_Kind (Candidate, End_Code) then
                  return D;
               end if;
            end;
         end loop;
         return 0;
      end Matching_End_Depth;

      procedure Recover_To_End_Boundary (End_Code : String; Line_No : Positive) is
         Match_Depth : Natural;
         Label       : constant String := "synchronize before " & End_Code;
      begin
         Pop_Alternative_Scope;
         Match_Depth := Matching_End_Depth (End_Code);

         if Match_Depth = 0 then
            Add_Recovery_Node
              (Node_Unexpected_End, Root_Node, 1, Line_No,
               "unexpected " & End_Code);
            Scope_Depth := 0;
         elsif Match_Depth < Scope_Depth then
            while Scope_Depth > Match_Depth loop
               declare
                  Open_Node : constant Node_Id := Scope_Stack (Scope_Depth);
                  Open_Kind : constant Node_Kind := Node (Tree, Open_Node).Kind;
                  Open_Depth : constant Natural := Node (Tree, Open_Node).Depth;
               begin
                  if Match_Depth > 0
                    and then End_Implicitly_Closes_Statement_Part
                      (Open_Kind, Node (Tree, Scope_Stack (Match_Depth)).Kind, End_Code)
                  then
                     Add_Recovery_Node
                       (Node_Implicit_End, Open_Node, Open_Depth + 1, Line_No,
                        "implicit close of " & Expected_End_Label (Open_Kind)
                        & " before " & End_Code);
                  else
                     Add_Recovery_Node
                       (Node_Missing_End, Open_Node, Open_Depth + 1, Line_No,
                        "insert " & Expected_End_Label (Open_Kind)
                        & " before " & End_Code);
                  end if;
                  Pop_Scope;
               end;
            end loop;
            Add_Recovery_Node
              (Node_Recovery_Point, Current_Parent,
               Node (Tree, Current_Parent).Depth + 1, Line_No, Label);
         end if;

         if Match_Depth /= 0 then
            declare
               Open_Node : constant Node_Id := Scope_Stack (Match_Depth);
               Open_Info : constant Node_Info := Node (Tree, Open_Node);
               Expected  : constant String := Opening_Target_Text
                 (Open_Info.Kind, To_String (Open_Info.Label));
               Actual    : constant String := End_Target_Text (End_Code);
            begin
               if Expected /= "" and then Actual /= ""
                 and then not Same_Ada_Name (Expected, Actual)
               then
                  declare
                     Recovery : constant Node_Id := Add_Node
                       (Tree, Node_Mismatched_End,
                        (Line_No, 1, Line_No, Last_Column_For (End_Code)),
                        Open_Node, Open_Info.Depth + 1,
                        "mismatched end target " & Actual
                        & " expected " & Expected);
                  begin
                     Add_Detail_Node
                       (Tree, Recovery, Open_Info.Depth + 2, Line_No,
                        Node_Expected_End_Target, Expected);
                     Add_Detail_Node
                       (Tree, Recovery, Open_Info.Depth + 2, Line_No,
                        Node_End_Target, Actual);
                  end;
               end if;
            end;
         end if;
      end Recover_To_End_Boundary;

      procedure Recover_Alternative_Owner
        (Kind    : Node_Kind;
         Line_No : Positive;
         Code    : String)
      is
      begin
         if Is_Alternative_Node (Kind) then
            while Scope_Depth > 0
              and then not Alternative_Has_Grammar_Owner (Kind, Current_Kind)
            loop
               declare
                  Open_Node : constant Node_Id := Current_Parent;
                  Open_Kind : constant Node_Kind := Current_Kind;
               begin
                  Add_Recovery_Node
                    (Node_Missing_End, Open_Node,
                     Node (Tree, Open_Node).Depth + 1, Line_No,
                     "insert " & Expected_End_Label (Open_Kind)
                     & " before " & Code);
                  Pop_Scope;
               end;
            end loop;

            if Scope_Depth = 0
              and then not Alternative_Has_Grammar_Owner (Kind, Node_Compilation_Unit)
            then
               Add_Recovery_Node
                 (Node_Mismatched_End, Root_Node, 1, Line_No,
                  "orphan alternative " & Code);
            end if;
         end if;
      end Recover_Alternative_Owner;


      function Starts_Generic_Unit (Kind : Node_Kind; Code : String) return Boolean is
         L : constant String := Lower (Code);
      begin
         if Kind = Node_Package_Declaration
           or else Kind = Node_Subprogram_Declaration
           or else Kind = Node_Abstract_Subprogram_Declaration
           or else Kind = Node_Null_Procedure_Declaration
           or else Kind = Node_Expression_Function_Declaration
           or else Kind = Node_Subprogram_Body
         then
            return Starts_With_Word (L, "package")
              or else Starts_With_Word (L, "procedure")
              or else Starts_With_Word (L, "function")
              or else Starts_With_Word (L, "overriding procedure")
              or else Starts_With_Word (L, "overriding function")
              or else Starts_With_Word (L, "not overriding procedure")
              or else Starts_With_Word (L, "not overriding function");
         end if;
         return False;
      end Starts_Generic_Unit;

      function Allows_Handled_Statement_Part (Kind : Node_Kind) return Boolean is
      begin
         return Kind = Node_Package_Body
           or else Kind = Node_Subprogram_Body
           or else Kind = Node_Task_Body
           or else Kind = Node_Entry_Body
           or else Kind = Node_Accept_Statement
           or else Kind = Node_Declare_Block;
      end Allows_Handled_Statement_Part;

      function Is_Executable_Statement_Node (Kind : Node_Kind) return Boolean is
      begin
         return Kind = Node_Begin_Block
           or else Kind = Node_If_Statement
           or else Kind = Node_Case_Statement
           or else Kind = Node_Loop_Statement
           or else Kind = Node_Declare_Block
           or else Kind = Node_Select_Statement
           or else Kind = Node_Accept_Statement
           or else Kind = Node_Entry_Call_Statement
           or else Kind = Node_Return_Statement
           or else Kind = Node_Raise_Statement
           or else Kind = Node_Assignment_Statement
           or else Kind = Node_Call_Statement
           or else Kind = Node_Null_Statement
           or else Kind = Node_Exit_Statement
           or else Kind = Node_Goto_Statement
           or else Kind = Node_Requeue_Statement
           or else Kind = Node_Delay_Statement
           or else Kind = Node_Abort_Statement
           or else Kind = Node_Terminate_Statement
           or else Kind = Node_Label;
      end Is_Executable_Statement_Node;

      function Is_Declaration_Node (Kind : Node_Kind) return Boolean is
      begin
         return Kind = Node_Package_Declaration
           or else Kind = Node_Package_Body
           or else Kind = Node_Subprogram_Declaration
           or else Kind = Node_Abstract_Subprogram_Declaration
           or else Kind = Node_Null_Procedure_Declaration
           or else Kind = Node_Expression_Function_Declaration
           or else Kind = Node_Subprogram_Body
           or else Kind = Node_Type_Declaration
           or else Kind = Node_Subtype_Declaration
           or else Kind = Node_Object_Declaration
           or else Kind = Node_Constant_Declaration
           or else Kind = Node_Deferred_Constant_Declaration
           or else Kind = Node_Number_Declaration
           or else Kind = Node_Component_Declaration
           or else Kind = Node_Discriminant_Specification
           or else Kind = Node_Parameter_Specification
           or else Kind = Node_Formal_Object_Declaration
           or else Kind = Node_Formal_Type_Declaration
           or else Kind = Node_Formal_Subprogram_Declaration
           or else Kind = Node_Formal_Package_Declaration
           or else Kind = Node_Exception_Declaration
           or else Kind = Node_Generic_Declaration
           or else Kind = Node_Rename_Declaration
           or else Kind = Node_Instantiation
           or else Kind = Node_Separate_Body
           or else Kind = Node_Task_Type_Declaration
           or else Kind = Node_Single_Task_Declaration
           or else Kind = Node_Task_Body
           or else Kind = Node_Protected_Type_Declaration
           or else Kind = Node_Single_Protected_Declaration
           or else Kind = Node_Protected_Body
           or else Kind = Node_Entry_Declaration
           or else Kind = Node_Entry_Body
           or else Kind = Node_Entry_Body_Stub
           or else Kind = Node_Incomplete_Type_Declaration
           or else Kind = Node_Private_Extension_Declaration
           or else Kind = Node_Body_Stub
           or else Kind = Node_Choice_Parameter_Specification
           or else Kind = Node_Enumeration_Literal_Declaration
           or else Kind = Node_Variant_Part
           or else Kind = Node_Variant;
      end Is_Declaration_Node;

      procedure Add_Unexpected_Declaration_Recovery
        (Line_No : Positive;
         Code    : String)
      is
         Owner    : constant Node_Id := Current_Parent;
         Recovery : Node_Id;
      begin
         Recovery := Add_Node
           (Tree, Node_Unexpected_Declaration,
            (Line_No, 1, Line_No, Last_Column_For (Code)),
            Owner, Node (Tree, Owner).Depth + 1,
            "declaration appears after handled sequence begin: " & Code);
         Add_Detail_Node
           (Tree, Recovery, Node (Tree, Owner).Depth + 2, Line_No,
            Node_Expected_Token, "declare");
         Add_Recovery_Node
           (Node_Recovery_Point, Recovery, Node (Tree, Owner).Depth + 2,
            Line_No,
            "move declaration before begin or introduce nested declare block");
      end Add_Unexpected_Declaration_Recovery;

      procedure Insert_Implicit_Begin_Before
        (Line_No : Positive;
         Code    : String)
      is
         Owner      : constant Node_Id := Current_Parent;
         Owner_Info : constant Node_Info := Node (Tree, Owner);
         Begin_Node : Node_Id;
         Recovery   : Node_Id;
      begin
         Begin_Node := Add_Node
           (Tree, Node_Implicit_Begin,
            (Line_No, 1, Line_No, Last_Column_For (Code)),
            Owner, Owner_Info.Depth + 1,
            "implicit begin before " & Code);
         Recovery := Add_Node
           (Tree, Node_Recovery_Point,
            (Line_No, 1, Line_No, Last_Column_For (Code)),
            Begin_Node, Owner_Info.Depth + 2,
            "malformed handled sequence: expected begin before " & Code);
         Add_Detail_Node
           (Tree, Recovery, Owner_Info.Depth + 3, Line_No,
            Node_Expected_Token, "begin");
         Push_Scope (Begin_Node);
      end Insert_Implicit_Begin_Before;

      procedure Add_EOF_Recovery (Line_No : Positive) is
      begin
         while Scope_Depth > 0 loop
            declare
               Open_Node  : constant Node_Id := Scope_Stack (Scope_Depth);
               Open_Kind  : constant Node_Kind := Node (Tree, Open_Node).Kind;
               Open_Depth : constant Natural := Node (Tree, Open_Node).Depth;
               Owner_Kind : constant Node_Kind :=
                 (if Scope_Depth > 1 then Node (Tree, Scope_Stack (Scope_Depth - 1)).Kind
                  else Node_Compilation_Unit);
            begin
               if Scope_Depth > 1
                 and then End_Implicitly_Closes_Statement_Part
                   (Open_Kind, Owner_Kind, "end of file")
               then
                  Add_Recovery_Node
                    (Node_Implicit_End, Open_Node, Open_Depth + 1, Line_No,
                     "implicit close of " & Expected_End_Label (Open_Kind)
                     & " at end of file");
               else
                  Add_Recovery_Node
                    (Node_Missing_End, Open_Node, Open_Depth + 1, Line_No,
                     "insert " & Expected_End_Label (Open_Kind) & " at end of file");
               end if;
               Pop_Scope;
            end;
         end loop;
      end Add_EOF_Recovery;


      procedure Attach_Token_Cursor_Grammar is
         Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
           Editor.Ada_Token_Cursor.Parse (Text);
         Parent  : Node_Id;
         Limit   : constant Natural := 192;
         Count   : constant Natural := Editor.Ada_Token_Cursor.Production_Count (Grammar);
      begin
         Parent := Add_Node
           (Tree, Node_Token_Cursor_Grammar, (1, 1, 1, 1),
            Root_Node, 1, "token cursor grammar");

         for Index in 1 .. Count loop
            exit when Index > Limit;
            declare
               Prod : constant Editor.Ada_Token_Cursor.Production_Info :=
                 Editor.Ada_Token_Cursor.Production_At (Grammar, Index);
               Label : constant String :=
                 Editor.Ada_Token_Cursor.Production_Kind'Image (Prod.Kind)
                 & ":" & To_String (Prod.Label);
            begin
               declare
                  Ignored : constant Node_Id := Add_Node
                    (Tree, Node_Grammar_Production,
                     (Prod.Line, Prod.Column, Prod.Line, Prod.Column),
                     Parent, 2, Label);
               begin
                  null;
               end;
            end;
         end loop;

         if Count > Limit then
            declare
               Ignored : constant Node_Id := Add_Node
                 (Tree, Node_Recovery_Point, (1, 1, 1, 1), Parent, 2,
                  "token cursor grammar production budget exceeded");
            begin
               null;
            end;
         end if;
      end Attach_Token_Cursor_Grammar;

      procedure Add_Line (Line : String; Line_No : Positive) is
         Classified  : constant Node_Kind := Classify_Line (Line);
         Code        : constant String :=
           Trim (Code_Preserving_Literals_For_Retention (Line));
         Last_Column : constant Positive := (if Line'Length = 0 then 1 else Line'Length);
         Parent      : Node_Id;
         New_Node    : Node_Id;
         Kind        : Node_Kind := Classified;
         Parent_Override : Node_Id := No_Node;
         L           : constant String := Lower (Code);
      begin
         if Code /= "" then
            if Scope_Depth > 0
              and then Current_Kind = Node_Generic_Declaration
              and then Starts_With_Word (L, "with package")
            then
               Kind := Node_Formal_Package_Declaration;
            elsif Scope_Depth > 0
              and then Current_Kind = Node_Generic_Declaration
              and then (Starts_With_Word (L, "with procedure")
                        or else Starts_With_Word (L, "with function"))
            then
               Kind := Node_Formal_Subprogram_Declaration;
            elsif Classified = Node_Pragma and then Scope_Depth > 0 then
               Kind := Node_Pragma_Statement;
            elsif Classified = Node_With_Clause and then Scope_Depth > 0 then
               Kind := Node_Aspect_Specification;
               if Last_Significant_Node /= No_Node then
                  declare
                     Prev : constant Node_Kind := Node (Tree, Last_Significant_Node).Kind;
                  begin
                     if Prev = Node_Package_Declaration
                       or else Prev = Node_Subprogram_Declaration
                       or else Prev = Node_Subprogram_Body
                       or else Prev = Node_Type_Declaration
                       or else Prev = Node_Subtype_Declaration
                       or else Prev = Node_Object_Declaration
                       or else Prev = Node_Exception_Declaration
                       or else Prev = Node_Instantiation
                     then
                        Parent_Override := Last_Significant_Node;
                     end if;
                  end;
               end if;
            elsif Starts_With (L, "(")
              and then Last_Significant_Node /= No_Node
              and then (Node (Tree, Last_Significant_Node).Kind = Node_Instantiation
                        or else Node (Tree, Last_Significant_Node).Kind =
                          Node_Formal_Package_Declaration)
              and then (Contains (L, "=>")
                        or else Node (Tree, Last_Significant_Node).Kind =
                          Node_Instantiation)
            then
               --  Split generic actual parts can follow ordinary
               --  instantiations and formal package declarations.  Formal
               --  keep the parentage so projection attributes those actuals
               --  to the formal package symbol instead of creating a detached
               --  top-level expression node.
               Kind := Node_Generic_Actual_Part;
               Parent_Override := Last_Significant_Node;
            end if;

            if Kind = Node_With_Clause
              or else (Kind = Node_Use_Clause and then Scope_Depth = 0)
              or else Kind = Node_Pragma
            then
               declare
                  Context : constant Node_Id :=
                    Add_Node (Tree, Node_Context_Clause,
                              (Line_No, 1, Line_No, Last_Column),
                              Root_Node, 1, "context");
               begin
                  declare
                     Child : constant Node_Id :=
                       Add_Node (Tree, Kind, (Line_No, 1, Line_No, Last_Column),
                                 Context, 2, Code);
                  begin
                     Attach_Syntax_Details (Tree, Child, Kind, Code, Line_No, 3);
                     Last_Significant_Node := Child;
                  end;
               end;
            else
               if Is_End_Node (Kind) then
                  Recover_To_End_Boundary (Code, Line_No);
               elsif Is_Alternative_Node (Kind) then
                  if Scope_Depth > 0
                    and then Classified = Node_When_Alternative
                    and then (Current_Kind = Node_Exception_Section
                              or else Current_Kind = Node_Exception_Handler)
                  then
                     Kind := Node_Exception_Handler;
                     Pop_Exception_Handler_Scope;
                  else
                     Pop_Alternative_Scope;
                  end if;
                  if Kind = Node_Exception_Section
                    and then Scope_Depth > 0
                    and then Current_Kind = Node_Begin_Block
                  then
                     Pop_Scope;
                  end if;
               end if;

               if Scope_Depth > 0
                 and then Current_Kind = Node_Generic_Declaration
                 and then Classified = Node_Type_Declaration
               then
                  Kind := Node_Formal_Type_Declaration;
               elsif Scope_Depth > 0
                 and then Current_Kind = Node_Generic_Declaration
                 and then Classified = Node_Object_Declaration
               then
                  Kind := Node_Formal_Object_Declaration;
               elsif Scope_Depth > 0
                 and then (Current_Kind = Node_Type_Declaration
                           or else Current_Kind = Node_Private_Extension_Declaration)
                 and then Classified = Node_Object_Declaration
               then
                  Kind := Node_Component_Declaration;
               elsif Scope_Depth > 0
                 and then (Current_Kind = Node_Type_Declaration
                           or else Current_Kind = Node_Private_Extension_Declaration)
                 and then Classified = Node_Case_Statement
               then
                  Kind := Node_Variant_Part;
               elsif Scope_Depth > 0
                 and then (Current_Kind = Node_Variant_Part
                           or else Current_Kind = Node_Variant)
                 and then Classified = Node_When_Alternative
               then
                  Kind := Node_Variant;
               elsif Scope_Depth > 0
                 and then Current_Kind = Node_Representation_Clause
                 and then Starts_With_Word (L, "at")
                 and then Contains (L, " mod ")
               then
                  Kind := Node_Representation_Mod_Clause;
               elsif Scope_Depth > 0
                 and then Current_Kind = Node_Representation_Clause
                 and then Contains (L, " at ")
                 and then Contains (L, " range ")
               then
                  Kind := Node_Representation_Component_Clause;
               elsif Scope_Depth > 0
                 and then Current_Kind = Node_Select_Statement
                 and then (Classified = Node_Else_Part
                           or else Classified = Node_Terminate_Statement)
               then
                  Kind := Node_Select_Alternative;
               elsif Scope_Depth > 0
                 and then Current_Kind = Node_Select_Statement
                 and then Classified = Node_Call_Statement
               then
                  Kind := Node_Entry_Call_Statement;
               elsif Scope_Depth > 0
                 and then Current_Kind = Node_Select_Alternative
                 and then Starts_With_Word (L, "terminate")
               then
                  Kind := Node_Select_Alternative;
               elsif Scope_Depth > 0
                 and then (Current_Kind = Node_Exception_Section
                           or else Current_Kind = Node_Exception_Handler)
                 and then Classified = Node_When_Alternative
               then
                  Kind := Node_Exception_Handler;
               end if;

               if Kind = Node_Select_Alternative
                 and then Classified /= Node_Select_Alternative
                 and then Scope_Depth > 0
                 and then Is_Alternative_Node (Current_Kind)
               then
                  Pop_Alternative_Scope;
               end if;

               if Scope_Depth > 0
                 and then Current_Kind = Node_Generic_Declaration
                 and then Starts_Generic_Unit (Kind, Code)
               then
                  declare
                     Generic_Node : constant Node_Id := Current_Parent;
                     Generic_Info : constant Node_Info := Node (Tree, Generic_Node);
                  begin
                     Add_Recovery_Node
                       (Node_Implicit_End, Generic_Node, Generic_Info.Depth + 1,
                        Line_No,
                        "implicit close of generic formal part before " & Code);
                     Parent_Override := Generic_Node;
                     Pop_Scope;
                  end;
               end if;

               if Scope_Depth > 0
                 and then Parent_Override = No_Node
                 and then (Current_Kind = Node_Begin_Block
                           or else Current_Kind = Node_Implicit_Begin)
                 and then Is_Declaration_Node (Kind)
               then
                  Add_Unexpected_Declaration_Recovery (Line_No, Code);
               end if;

               if Scope_Depth > 0
                 and then Parent_Override = No_Node
                 and then Allows_Handled_Statement_Part (Current_Kind)
                 and then Is_Executable_Statement_Node (Kind)
                 and then Kind /= Node_Begin_Block
               then
                  Insert_Implicit_Begin_Before (Line_No, Code);
               end if;

               if Is_Alternative_Node (Kind) then
                  Recover_Alternative_Owner (Kind, Line_No, Code);
               end if;

               Parent := (if Parent_Override /= No_Node then Parent_Override else Current_Parent);
               New_Node := Add_Node (Tree, Kind, (Line_No, 1, Line_No, Last_Column),
                                     Parent,
                                     (if Parent_Override /= No_Node then Node (Tree, Parent_Override).Depth + 1 else Scope_Depth + 1),
                                     Code);
               Attach_Syntax_Details
                 (Tree, New_Node, Kind, Code, Line_No,
                  (if Parent_Override /= No_Node then Node (Tree, Parent_Override).Depth + 2 else Scope_Depth + 2));
               Last_Significant_Node := New_Node;

               if Is_End_Node (Kind) then
                  Pop_Scope;
               elsif Opens_Scope (Kind, Code) then
                  Push_Scope (New_Node);
               end if;
            end if;
         end if;
      end Add_Line;
   begin
      Clear (Tree);
      Root_Node := Add_Node (Tree, Node_Compilation_Unit, (1, 1, 1, 1),
                             No_Node, 0, "compilation_unit");

      Attach_Token_Cursor_Grammar;

      if Text'Length = 0 then
         return Tree;
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
                  Add_Line (Text (Line_Start .. Line_End), Line_Number);
               else
                  Add_Line ("", Line_Number);
               end if;
            end;
            if I < Text'Last then
               Line_Start := I + 1;
            end if;
            Line_Number := Line_Number + 1;
         end if;
      end loop;

      if Line_Start <= Text'Last then
         declare
            Line_End : Natural := Text'Last;
         begin
            if Text (Line_End) = Ada.Characters.Latin_1.CR then
               Line_End := Line_End - 1;
            end if;
            if Line_End >= Line_Start then
               Add_Line (Text (Line_Start .. Line_End), Line_Number);
            end if;
         end;
      end if;

      Add_EOF_Recovery (Line_Number);

      return Tree;
   end Parse;
