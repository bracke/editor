with Ada.Strings.Fixed;
with Editor.Ada_Syntax_Tree.Builder;
with Editor.Text_Helpers;

package body Editor.Ada_Syntax_Tree.Detail_Nodes is

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Trim (S : String) return String
     renames Editor.Text_Helpers.Trim;

   function Starts_With_Word (Text, Word : String) return Boolean
     renames Editor.Text_Helpers.Starts_With_Word;

   function Contains (Text, Fragment : String) return Boolean
     renames Editor.Text_Helpers.Contains;

   function Is_Identifier_Start (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z') or else (C >= 'a' and then C <= 'z');
   end Is_Identifier_Start;

   function Is_Identifier_Part (C : Character) return Boolean is
   begin
      return Is_Identifier_Start (C) or else (C >= '0' and then C <= '9') or else C = '_';
   end Is_Identifier_Part;

   function Is_Keyword (Word : String) return Boolean is
      L : constant String := Lower (Word);
   begin
      return L = "abort" or else L = "abs" or else L = "abstract"
        or else L = "accept" or else L = "access" or else L = "aliased"
        or else L = "all" or else L = "and" or else L = "array"
        or else L = "at" or else L = "begin" or else L = "body"
        or else L = "case" or else L = "constant" or else L = "declare"
        or else L = "delay" or else L = "delta" or else L = "digits"
        or else L = "do" or else L = "else" or else L = "elsif"
        or else L = "end" or else L = "entry" or else L = "exception"
        or else L = "exit" or else L = "for" or else L = "function"
        or else L = "generic" or else L = "goto" or else L = "if"
        or else L = "in" or else L = "interface" or else L = "is"
        or else L = "limited" or else L = "loop" or else L = "mod"
        or else L = "new" or else L = "not" or else L = "null"
        or else L = "of" or else L = "or" or else L = "others"
        or else L = "out" or else L = "overriding" or else L = "package"
        or else L = "pragma" or else L = "private" or else L = "procedure"
        or else L = "protected" or else L = "raise" or else L = "range"
        or else L = "record" or else L = "rem" or else L = "renames"
        or else L = "requeue" or else L = "return" or else L = "reverse"
        or else L = "select" or else L = "separate" or else L = "some"
        or else L = "subtype" or else L = "synchronized" or else L = "tagged"
        or else L = "task" or else L = "terminate" or else L = "then"
        or else L = "type" or else L = "until" or else L = "use"
        or else L = "when" or else L = "while" or else L = "with"
        or else L = "xor";
   end Is_Keyword;

   function Strip_Terminator (Text : String) return String is
      T : constant String := Trim (Text);
   begin
      if T'Length > 0 and then T (T'Last) = ';' then
         return Trim (T (T'First .. T'Last - 1));
      end if;
      return T;
   end Strip_Terminator;

   function Segment_Before (Text, Marker : String) return String is
      Marker_Pos : constant Natural := Ada.Strings.Fixed.Index (Lower (Text), Lower (Marker));
   begin
      if Marker_Pos = 0 then
         return Trim (Text);
      elsif Marker_Pos <= Text'First then
         return "";
      else
         return Trim (Text (Text'First .. Marker_Pos - 1));
      end if;
   end Segment_Before;

   function Segment_After (Text, Marker : String) return String is
      Marker_Pos : constant Natural := Ada.Strings.Fixed.Index (Lower (Text), Lower (Marker));
      First : Natural;
   begin
      if Marker_Pos = 0 then
         return "";
      end if;
      First := Marker_Pos + Marker'Length;
      if First > Text'Last then
         return "";
      end if;
      return Trim (Text (First .. Text'Last));
   end Segment_After;

   procedure Add_Syntax_Child
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Kind   : Node_Kind;
      Label  : String)
   is
      Clean : constant String := Strip_Terminator (Label);
      Last_Column : constant Positive := (if Clean'Length = 0 then 1 else Clean'Length);
      Ignored : Node_Id;
   begin
      if Clean /= "" then
         Ignored := Builder.Add_Node
           (Tree, Kind, (Line, 1, Line, Last_Column), Parent, Depth, Clean);
      end if;
   end Add_Syntax_Child;

   function Looks_Like_Literal (Text : String) return Boolean is
      T : constant String := Trim (Text);
      L : constant String := Lower (T);
   begin
      if T = "" then
         return False;
      end if;
      return (T (T'First) >= '0' and then T (T'First) <= '9')
        or else T (T'First) = '"'
        or else (T'Length >= 3
                 and then T (T'First) = Character'Val (39)
                 and then T (T'Last) = Character'Val (39))
        or else L = "true"
        or else L = "false"
        or else L = "null";
   end Looks_Like_Literal;

   function Has_Operator (Text : String) return Boolean is
      L : constant String := Lower (Text);
   begin
      return Contains (L, " + ") or else Contains (L, " - ")
        or else Contains (L, " * ") or else Contains (L, " / ")
        or else Contains (L, " = ") or else Contains (L, " /= ")
        or else Contains (L, " < ") or else Contains (L, " > ")
        or else Contains (L, " <= ") or else Contains (L, " >= ")
        or else Contains (L, " and ") or else Contains (L, " or ")
        or else Contains (L, " xor ") or else Contains (L, " mod ")
        or else Contains (L, " rem ") or else Contains (L, " in ")
        or else Starts_With_Word (L, "not") or else Starts_With_Word (L, "abs");
   end Has_Operator;

   procedure Add_Name_Tokens
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      I : Natural := Text'First;
   begin
      while I <= Text'Last loop
         if Is_Identifier_Start (Text (I)) then
            declare
               First : constant Natural := I;
               Last  : Natural := I;
            begin
               while Last < Text'Last and then Is_Identifier_Part (Text (Last + 1)) loop
                  Last := Last + 1;
               end loop;
               declare
                  Word : constant String := Text (First .. Last);
               begin
                  if not Is_Keyword (Word) then
                     Add_Syntax_Child (Tree, Parent, Depth, Line, Node_Name, Word);
                  end if;
               end;
               I := Last + 1;
            end;
         else
            I := I + 1;
         end if;
      end loop;
   end Add_Name_Tokens;

   procedure Add_Expression_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Clean : constant String := Strip_Terminator (Text);
      L     : constant String := Lower (Clean);
      Expr  : Node_Id;
      Last_Column : constant Positive := (if Clean'Length = 0 then 1 else Clean'Length);
   begin
      if Clean = "" then
         return;
      end if;

      Expr := Builder.Add_Node
        (Tree, Node_Expression, (Line, 1, Line, Last_Column), Parent, Depth, Clean);

      if Looks_Like_Literal (Clean) then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Literal, Clean);
      end if;
      if Contains (Clean, "=>") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Association, Clean);
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Named_Association, Clean);
         Add_Expression_Nodes (Tree, Expr, Depth + 1, Line, Segment_Before (Clean, "=>"));
         Add_Expression_Nodes (Tree, Expr, Depth + 1, Line, Segment_After (Clean, "=>"));
      elsif Contains (Clean, ",") and then Contains (Clean, "(") and then Contains (Clean, ")") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Association, Clean);
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Positional_Association, Clean);
      end if;
      if Starts_With_Word (L, "raise") and then Contains (L, " with ") then
         Add_Expression_Nodes (Tree, Expr, Depth + 1, Line, Segment_Before (Segment_After (Clean, "raise"), "with"));
         Add_Expression_Nodes (Tree, Expr, Depth + 1, Line, Segment_After (Clean, "with"));
      end if;
      if Starts_With_Word (L, "new") or else Contains (L, " new ") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Allocator, Clean);
      end if;
      if Contains (L, ".all") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Explicit_Dereference, Clean);
      end if;
      if Contains (Clean, "'(") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Qualified_Expression, Clean);
      elsif Contains (Clean, "'") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Attribute_Reference, Clean);
      end if;
      if Contains (Clean, "..") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Range_Expression, Clean);
      end if;
      if Contains (L, " in ") or else Contains (L, " not in ") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Membership_Expression, Clean);
      end if;
      if Contains (L, " and then ") or else Contains (L, " or else ") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Short_Circuit_Expression, Clean);
         if Contains (L, " and then ") then
            Add_Expression_Nodes
              (Tree, Expr, Depth + 1, Line, Segment_Before (Clean, " and then "));
            Add_Expression_Nodes
              (Tree, Expr, Depth + 1, Line, Segment_After (Clean, " and then "));
         elsif Contains (L, " or else ") then
            Add_Expression_Nodes
              (Tree, Expr, Depth + 1, Line, Segment_Before (Clean, " or else "));
            Add_Expression_Nodes
              (Tree, Expr, Depth + 1, Line, Segment_After (Clean, " or else "));
         end if;
      end if;
      if Starts_With_Word (L, "not") or else Starts_With_Word (L, "abs")
        or else (Clean'Length > 1 and then (Clean (Clean'First) = '-' or else Clean (Clean'First) = '+'))
      then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Unary_Expression, Clean);
      end if;
      if Clean'Length >= 2 and then Clean (Clean'First) = '(' and then Clean (Clean'Last) = ')' then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Parenthesized_Expression, Clean);
      end if;
      if Contains (L, "(if ") or else Starts_With_Word (L, "if") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Conditional_Expression, Clean);
      end if;
      if Contains (L, "(case ") or else Starts_With_Word (L, "case") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Case_Expression, Clean);
      end if;
      if Contains (L, "for all") or else Contains (L, "for some")
        or else Starts_With_Word (L, "for")
      then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Quantified_Expression, Clean);
      end if;
      if Starts_With_Word (L, "declare") or else Contains (L, "(declare ") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Declare_Expression, Clean);
      end if;
      if Contains (L, " with delta ") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Delta_Aggregate, Clean);
      end if;
      if Contains (L, "'reduce")
        or else Contains (L, "'parallel_reduce")
        or else Contains (L, "'map_reduce")
      then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Reduction_Expression, Clean);
      end if;
      if (Contains (L, " for ") or else Contains (L, "(for "))
        and then Contains (Clean, "=>")
        and then Contains (Clean, "(") and then Contains (Clean, ")")
      then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Container_Aggregate, Clean);
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Iterator_Specification, Clean);
      end if;
      if Contains (Clean, "@") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Target_Name, "@");
      end if;
      if Has_Operator (Clean) then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Operator_Expression, Clean);
      end if;
      if Contains (Clean, ".") then
         Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Selected_Name, Clean);
      end if;
      if Contains (Clean, "(") and then Contains (Clean, ")") then
         if not Contains (Clean, "=>") then
            Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Association, Clean);
            Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Positional_Association, Clean);
         end if;

         if Clean (Clean'First) = '(' then
            Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Aggregate, Clean);
         elsif Contains (Clean, "..") then
            Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Slice, Clean);
         else
            Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Function_Call, Clean);
            Add_Syntax_Child (Tree, Expr, Depth + 1, Line, Node_Indexed_Component, Clean);
         end if;
      end if;

      Add_Name_Tokens (Tree, Expr, Depth + 1, Line, Clean);
   end Add_Expression_Nodes;

   function Last_Column_For (Text : String) return Positive is
   begin
      if Text'Length = 0 then
         return 1;
      end if;
      return Positive (Text'Length);
   end Last_Column_For;

   procedure Add_Detail_Node
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Kind   : Node_Kind;
      Label  : String)
   is
      Id    : Node_Id;
   begin
      if Kind = Node_Expected_Token then
         declare
            Token : constant String := Trim (Label);
         begin
            if Token /= "" then
               Id := Builder.Add_Node
                 (Tree, Kind, (Line, 1, Line, Last_Column_For (Token)),
                  Parent, Depth, Token);
            end if;
         end;
         return;
      end if;

      declare
         Clean : constant String := Strip_Terminator (Label);
      begin
         if Clean /= "" then
            Id := Builder.Add_Node
              (Tree, Kind, (Line, 1, Line, Last_Column_For (Clean)), Parent, Depth, Clean);
            if Kind = Node_Statement_Action
              or else Kind = Node_Statement_Target
              or else Kind = Node_Statement_Condition
              or else Kind = Node_Statement_Selector
              or else Kind = Node_Statement_Arguments
              or else Kind = Node_Statement_Message
              or else Kind = Node_Declaration_Default
              or else Kind = Node_Aspect_Value
              or else Kind = Node_Generic_Actual_Value
            then
               Add_Expression_Nodes (Tree, Id, Depth + 1, Line, Clean);
            end if;
         end if;
      end;
   end Add_Detail_Node;

end Editor.Ada_Syntax_Tree.Detail_Nodes;
