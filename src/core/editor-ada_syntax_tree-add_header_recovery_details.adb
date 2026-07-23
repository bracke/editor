with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Syntax_Tree.Builder;
with Editor.Ada_Syntax_Tree.Detail_Nodes;
with Editor.Ada_Syntax_Tree.Line_Classifier;
with Editor.Ada_Syntax_Tree.Statement_Details;
with Editor.Ada_Token_Cursor;
with Editor.Text_Helpers;

separate (Editor.Ada_Syntax_Tree)
   procedure Add_Header_Recovery_Details
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Kind   : Node_Kind;
      Code   : String)
   is
      L : constant String := Lower (Code);

      procedure Add_Expected (Token : String; Context : String) is
         Recovery : Node_Id;
      begin
         Recovery := Add_Node
           (Tree, Node_Recovery_Point,
            (Line, 1, Line, Last_Column_For (Context)), Parent, Depth,
            "malformed header: expected " & Token & " in " & Context);
         Add_Detail_Node (Tree, Recovery, Depth + 1, Line, Node_Expected_Token, Token);
      end Add_Expected;

      procedure Add_Expected_Declaration_Token (Token : String) is
         Recovery : Node_Id;
      begin
         Recovery := Add_Node
           (Tree, Node_Recovery_Point,
            (Line, 1, Line, Last_Column_For (Code)), Parent, Depth,
            "malformed declaration: expected " & Token & " in " & Code);
         Add_Detail_Node (Tree, Recovery, Depth + 1, Line, Node_Expected_Token, Token);
      end Add_Expected_Declaration_Token;

      function Has_Terminator return Boolean is
      begin
         return Contains (L, ";");
      end Has_Terminator;

      function Open_Paren_Count return Natural is
         Count : Natural := 0;
      begin
         for Ch of Code loop
            if Ch = '(' then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Open_Paren_Count;

      function Close_Paren_Count return Natural is
         Count : Natural := 0;
      begin
         for Ch of Code loop
            if Ch = ')' then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Close_Paren_Count;

      procedure Add_Expected_Token
        (Token   : String;
         Context : String := "malformed grammar")
      is
         Recovery : Node_Id;
      begin
         Recovery := Add_Node
           (Tree, Node_Recovery_Point,
            (Line, 1, Line, Last_Column_For (Code)), Parent, Depth,
            Context & ": expected " & Token & " in " & Code);
         Add_Detail_Node (Tree, Recovery, Depth + 1, Line, Node_Expected_Token, Token);
      end Add_Expected_Token;

      procedure Add_Unbalanced_Paren_Recovery is
      begin
         if Open_Paren_Count > Close_Paren_Count then
            Add_Expected_Token (")", "malformed delimited list");
         elsif Close_Paren_Count > Open_Paren_Count then
            Add_Expected_Token ("(", "malformed delimited list");
         end if;
      end Add_Unbalanced_Paren_Recovery;
   begin
      case Kind is
         when Node_Package_Declaration | Node_Package_Body =>
            if not Contains (L, " is")
              and then not Contains (L, " renames ")
              and then not Contains (L, " new ")
            then
               Add_Expected_Declaration_Token ("is");
            end if;
         when Node_Subprogram_Body
            | Node_Task_Body
            | Node_Protected_Body
            | Node_Body_Stub
            | Node_Entry_Body_Stub =>
            if not Contains (L, " is") then
               Add_Expected_Declaration_Token ("is");
            end if;
         when Node_Subprogram_Declaration
            | Node_Abstract_Subprogram_Declaration
            | Node_Null_Procedure_Declaration
            | Node_Expression_Function_Declaration =>
            if Contains (L, " is") then
               null;
            elsif Contains (L, " begin") or else Contains (L, " end ") then
               Add_Expected_Declaration_Token ("is");
            elsif not Has_Terminator then
               Add_Expected_Declaration_Token (";");
            end if;
         when Node_Task_Type_Declaration
            | Node_Single_Task_Declaration
            | Node_Protected_Type_Declaration
            | Node_Single_Protected_Declaration =>
            if Contains (L, " is") then
               null;
            elsif not Has_Terminator then
               Add_Expected_Declaration_Token (";");
            end if;
         when Node_Type_Declaration | Node_Private_Extension_Declaration =>
            if not Contains (L, " is") then
               Add_Expected_Declaration_Token ("is");
            elsif not Contains (L, " record")
              and then not Contains (L, " with record")
              and then not Has_Terminator
            then
               Add_Expected_Declaration_Token (";");
            end if;
         when Node_Subtype_Declaration =>
            if not Contains (L, " is") then
               Add_Expected_Declaration_Token ("is");
            end if;
            if not Has_Terminator then
               Add_Expected_Declaration_Token (";");
            end if;
         when Node_Object_Declaration
            | Node_Constant_Declaration
            | Node_Deferred_Constant_Declaration
            | Node_Number_Declaration
            | Node_Component_Declaration
            | Node_Parameter_Specification
            | Node_Discriminant_Specification
            | Node_Exception_Declaration
            | Node_Rename_Declaration
            | Node_Instantiation
            | Node_Entry_Declaration
            | Node_Formal_Object_Declaration
            | Node_Formal_Type_Declaration
            | Node_Formal_Subprogram_Declaration
            | Node_Formal_Package_Declaration =>
            if not Has_Terminator then
               Add_Expected_Declaration_Token (";");
            end if;
         when Node_If_Statement =>
            if not Contains (L, " then") then
               Add_Expected ("then", Code);
            end if;
         when Node_Elsif_Part =>
            if not Contains (L, " then") then
               Add_Expected ("then", Code);
            end if;
         when Node_Case_Statement =>
            if not Contains (L, " is") then
               Add_Expected ("is", Code);
            end if;
         when Node_Variant_Part =>
            if not Contains (L, " is") then
               Add_Expected ("is", Code);
            end if;
         when Node_When_Alternative
            | Node_Exception_Handler
            | Node_Variant =>
            if not Contains (L, "=>") then
               Add_Expected ("=>", Code);
            end if;
         when Node_Loop_Statement =>
            if (Starts_With_Word (L, "for") or else Starts_With_Word (L, "while"))
              and then not Contains (L, " loop")
            then
               Add_Expected ("loop", Code);
            end if;
         when Node_Select_Statement =>
            if Contains (L, " then abort")
              and then not Contains (L, "select")
            then
               Add_Expected ("select", Code);
            end if;
         when Node_Accept_Statement =>
            if Contains (L, " do") and then Contains (L, " end ") then
               null;
            elsif Contains (L, " do") then
               null;
            elsif Contains (L, " end ") then
               Add_Expected ("do", Code);
            end if;
         when Node_Entry_Body =>
            if not Contains (L, " when") then
               Add_Expected ("when", Code);
            end if;
            if not Contains (L, " is") then
               Add_Expected ("is", Code);
            end if;
         when Node_End =>
            if not Has_Terminator then
               Add_Expected_Token (";", "malformed end boundary");
            end if;
         when Node_Pragma | Node_Pragma_Statement =>
            Add_Unbalanced_Paren_Recovery;
            if not Has_Terminator then
               Add_Expected_Token (";", "malformed pragma");
            end if;
         when Node_Aspect_Specification
            | Node_Representation_Clause
            | Node_Representation_Component_Clause
            | Node_Representation_Mod_Clause
            | Node_Generic_Actual_Part =>
            Add_Unbalanced_Paren_Recovery;
            if not Has_Terminator then
               Add_Expected_Token (";", "malformed metadata clause");
            end if;
         when others =>
            null;
      end case;
   end Add_Header_Recovery_Details;
