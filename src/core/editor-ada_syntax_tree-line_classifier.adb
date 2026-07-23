with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Text_Helpers;

package body Editor.Ada_Syntax_Tree.Line_Classifier is

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Trim (S : String) return String
     renames Editor.Text_Helpers.Trim;

   function Starts_With (Text, Prefix : String) return Boolean
     renames Editor.Text_Helpers.Starts_With;

   function Starts_With_Word (Text, Word : String) return Boolean
     renames Editor.Text_Helpers.Starts_With_Word;

   function Contains (Text, Fragment : String) return Boolean
     renames Editor.Text_Helpers.Contains;

   function Has_Declaration_Colon (Text : String) return Boolean is
   begin
      for I in Text'Range loop
         if Text (I) = ':'
           and then (I = Text'Last or else Text (I + 1) /= '=')
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Declaration_Colon;

   function Is_Deferred_Constant_Declaration_Line (Text : String) return Boolean is
      L : constant String := Lower (Text);
   begin
      return Contains (L, ": constant")
        and then not Contains (L, ":=");
   end Is_Deferred_Constant_Declaration_Line;

   function Is_Number_Declaration_Line (Text : String) return Boolean is
      L : constant String := Lower (Text);
   begin
      return Contains (L, ": constant :=");
   end Is_Number_Declaration_Line;

   function Is_Constant_Declaration_Line (Text : String) return Boolean is
      L : constant String := Lower (Text);
   begin
      return Contains (L, ": constant ")
        and then Contains (L, ":=")
        and then not Is_Number_Declaration_Line (Text);
   end Is_Constant_Declaration_Line;

   function Strip_Declaration_Prefixes (Text : String) return String is
      T : Unbounded_String := To_Unbounded_String (Trim (Text));
   begin
      loop
         declare
            Work : constant String := To_String (T);
            L    : constant String := Lower (Work);
         begin
            if Starts_With_Word (L, "not") and then Contains (L, " overriding") then
               if Work'Length > 14 then
                  T := To_Unbounded_String (Trim (Work (Work'First + 14 .. Work'Last)));
               else
                  T := Null_Unbounded_String;
               end if;
            elsif Starts_With_Word (L, "overriding") then
               if Work'Length > 10 then
                  T := To_Unbounded_String (Trim (Work (Work'First + 10 .. Work'Last)));
               else
                  T := Null_Unbounded_String;
               end if;
            elsif Starts_With_Word (L, "abstract") then
               if Work'Length > 8 then
                  T := To_Unbounded_String (Trim (Work (Work'First + 8 .. Work'Last)));
               else
                  T := Null_Unbounded_String;
               end if;
            else
               return Work;
            end if;
         end;
      end loop;
   end Strip_Declaration_Prefixes;

   function Classify_Line (Line : String) return Node_Kind is
      Code : constant String := Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
      Lead : constant String := Strip_Declaration_Prefixes (Code);
      L    : constant String := Lower (Lead);
      Full_L : constant String := Lower (Code);
   begin
      if L = "" then
         return Node_Unknown;
      elsif Starts_With_Word (L, "limited") and then Contains (L, " with ") then
         return Node_With_Clause;
      elsif Starts_With_Word (L, "private") and then Contains (L, " with ") then
         return Node_With_Clause;
      elsif Starts_With_Word (L, "with") then
         return Node_With_Clause;
      elsif Starts_With_Word (L, "use") then
         return Node_Use_Clause;
      elsif Starts_With_Word (L, "pragma") then
         return Node_Pragma;
      elsif Starts_With_Word (L, "private") and then (L = "private" or else L = "private;") then
         return Node_Private_Part;
      elsif Starts_With_Word (L, "use") and then (Contains (L, " type ") or else Contains (L, " all type ")) then
         return Node_Use_Clause;
      elsif Starts_With_Word (L, "for")
        and then (Contains (L, " use ") or else Contains (L, " at "))
        and then not Contains (L, " loop")
      then
         return Node_Representation_Clause;
      elsif Starts_With_Word (L, "generic") then
         return Node_Generic_Declaration;
      elsif Starts_With_Word (L, "separate") then
         return Node_Separate_Body;
      elsif (Starts_With_Word (L, "procedure") or else Starts_With_Word (L, "function")
             or else Starts_With_Word (L, "package")
             or else Starts_With_Word (L, "task")
             or else Starts_With_Word (L, "protected"))
        and then Contains (L, " is separate")
      then
         return Node_Body_Stub;
      elsif Starts_With_Word (L, "task body") then
         return Node_Task_Body;
      elsif Starts_With_Word (L, "task type") then
         return Node_Task_Type_Declaration;
      elsif Starts_With_Word (L, "task") then
         return Node_Single_Task_Declaration;
      elsif Starts_With_Word (L, "protected body") then
         return Node_Protected_Body;
      elsif Starts_With_Word (L, "protected type") then
         return Node_Protected_Type_Declaration;
      elsif Starts_With_Word (L, "protected") then
         return Node_Single_Protected_Declaration;
      elsif Starts_With_Word (L, "entry") then
         if Contains (L, " is separate") then
            return Node_Entry_Body_Stub;
         elsif Contains (L, " when ") and then Contains (L, " is") then
            return Node_Entry_Body;
         else
            return Node_Entry_Declaration;
         end if;
      elsif Starts_With_Word (L, "package body") then
         return Node_Package_Body;
      elsif Starts_With_Word (L, "package") and then Contains (L, " renames ") then
         return Node_Rename_Declaration;
      elsif Starts_With_Word (L, "package") and then Contains (L, " new ") then
         return Node_Instantiation;
      elsif Starts_With_Word (L, "package") then
         return Node_Package_Declaration;
      elsif Starts_With_Word (L, "procedure") or else Starts_With_Word (L, "function") then
         if Contains (L, " renames ") then
            return Node_Rename_Declaration;
         elsif Contains (L, " is new ") then
            return Node_Instantiation;
         elsif Contains (L, " is abstract") then
            return Node_Abstract_Subprogram_Declaration;
         elsif Starts_With_Word (L, "procedure") and then Contains (L, " is null") then
            return Node_Null_Procedure_Declaration;
         elsif Starts_With_Word (L, "function") and then Contains (L, " is (") then
            return Node_Expression_Function_Declaration;
         elsif Contains (L, " is") then
            return Node_Subprogram_Body;
         else
            return Node_Subprogram_Declaration;
         end if;
      elsif Starts_With_Word (L, "type") then
         if Contains (L, " with private") then
            return Node_Private_Extension_Declaration;
         elsif Contains (L, ";") and then not Contains (L, " is ") then
            return Node_Incomplete_Type_Declaration;
         else
            return Node_Type_Declaration;
         end if;
      elsif Starts_With_Word (L, "subtype") then
         return Node_Subtype_Declaration;
      elsif Starts_With_Word (L, "begin") then
         return Node_Begin_Block;
      elsif Starts_With_Word (L, "if") then
         return Node_If_Statement;
      elsif Starts_With_Word (L, "case") then
         return Node_Case_Statement;
      elsif Starts_With_Word (L, "loop") or else Starts_With_Word (L, "while")
        or else Starts_With_Word (L, "for")
      then
         return Node_Loop_Statement;
      elsif Starts_With_Word (L, "declare") then
         return Node_Declare_Block;
      elsif Starts_With_Word (L, "select") then
         return Node_Select_Statement;
      elsif Starts_With_Word (L, "then") and then Contains (L, "then abort") then
         return Node_Select_Alternative;
      elsif Starts_With_Word (L, "accept") then
         return Node_Accept_Statement;
      elsif Starts_With_Word (L, "elsif") then
         return Node_Elsif_Part;
      elsif Starts_With_Word (L, "else") then
         return Node_Else_Part;
      elsif Starts_With_Word (L, "when") then
         return Node_When_Alternative;
      elsif Starts_With_Word (L, "or") then
         return Node_Select_Alternative;
      elsif Starts_With_Word (L, "exception") then
         return Node_Exception_Section;
      elsif Starts_With_Word (L, "return") then
         return Node_Return_Statement;
      elsif Starts_With_Word (L, "raise") then
         return Node_Raise_Statement;
      elsif Starts_With_Word (L, "exit") then
         return Node_Exit_Statement;
      elsif Starts_With_Word (L, "goto") then
         return Node_Goto_Statement;
      elsif Starts_With_Word (L, "requeue") then
         return Node_Requeue_Statement;
      elsif Starts_With_Word (L, "delay") then
         return Node_Delay_Statement;
      elsif Starts_With_Word (L, "abort") then
         return Node_Abort_Statement;
      elsif Starts_With_Word (L, "terminate") then
         return Node_Terminate_Statement;
      elsif Starts_With (L, "<<") and then Contains (L, ">>") then
         return Node_Label;
      elsif Starts_With_Word (L, "null") then
         return Node_Null_Statement;
      elsif Starts_With_Word (L, "end") then
         return Node_End;
      elsif Contains (L, " renames ") and then Has_Declaration_Colon (L) and then Contains (L, ";") then
         return Node_Rename_Declaration;
      elsif Is_Number_Declaration_Line (L) then
         return Node_Number_Declaration;
      elsif Is_Deferred_Constant_Declaration_Line (L) then
         return Node_Deferred_Constant_Declaration;
      elsif Is_Constant_Declaration_Line (L) then
         return Node_Constant_Declaration;
      elsif Has_Declaration_Colon (L) then
         return Node_Object_Declaration;
      elsif Contains (L, ":=") then
         return Node_Assignment_Statement;
      elsif Contains (L, "(") or else Contains (L, ";") then
         return Node_Call_Statement;
      else
         return Node_Unknown;
      end if;
   end Classify_Line;

   function Opens_Scope (Kind : Node_Kind; Code : String) return Boolean is
      L : constant String := Lower (Code);
   begin
      case Kind is
         when Node_Package_Declaration | Node_Package_Body =>
            return not Contains (L, " end ");
         when Node_Generic_Declaration =>
            return True;
         when Node_Task_Declaration | Node_Task_Type_Declaration |
              Node_Single_Task_Declaration | Node_Task_Body |
              Node_Protected_Declaration | Node_Protected_Type_Declaration |
              Node_Single_Protected_Declaration | Node_Protected_Body =>
            return not Contains (L, " end ");
         when Node_Subprogram_Body =>
            return not Contains (L, " is null")
              and then not Contains (L, " is (")
              and then not Contains (L, " end ");
         when Node_If_Statement =>
            return not Contains (L, " end if");
         when Node_Case_Statement =>
            return not Contains (L, " end case");
         when Node_Loop_Statement =>
            return not Contains (L, " end loop");
         when Node_Declare_Block =>
            return not Contains (L, " end");
         when Node_Begin_Block =>
            return not Contains (L, " end");
         when Node_Select_Statement =>
            return not Contains (L, " end select");
         when Node_Type_Declaration =>
            return (Contains (L, " record") or else Contains (L, " record;")
                    or else Contains (L, " is record")
                    or else Contains (L, " with record"))
              and then not Contains (L, " null record")
              and then not Contains (L, " end record");
         when Node_Representation_Clause =>
            return Contains (L, " use record")
              and then not Contains (L, " end record");
         when Node_Accept_Statement =>
            return Contains (L, " do") and then not Contains (L, " end ");
         when Node_Entry_Body =>
            return not Contains (L, " end ");
         when Node_Variant_Part | Node_Variant =>
            return True;
         when Node_Private_Part =>
            return True;
         when Node_Elsif_Part
            | Node_Else_Part
            | Node_When_Alternative
            | Node_Exception_Handler
            | Node_Exception_Section =>
            return True;
         when Node_Select_Alternative =>
            return not Starts_With_Word (L, "terminate")
              and then not Contains (L, " end select");
         when others =>
            return False;
      end case;
   end Opens_Scope;

   function Is_End_Node (Kind : Node_Kind) return Boolean is
   begin
      return Kind = Node_End;
   end Is_End_Node;

   function Is_Alternative_Node (Kind : Node_Kind) return Boolean is
   begin
      return Kind = Node_Elsif_Part
        or else Kind = Node_Else_Part
        or else Kind = Node_When_Alternative
        or else Kind = Node_Select_Alternative
        or else Kind = Node_Exception_Handler
        or else Kind = Node_Exception_Section
        or else Kind = Node_Variant;
   end Is_Alternative_Node;

   function Expected_End_Label (Kind : Node_Kind) return String is
   begin
      case Kind is
         when Node_If_Statement | Node_Elsif_Part | Node_Else_Part =>
            return "end if";
         when Node_Case_Statement | Node_When_Alternative =>
            return "end case";
         when Node_Loop_Statement =>
            return "end loop";
         when Node_Select_Statement | Node_Select_Alternative =>
            return "end select";
         when Node_Variant_Part | Node_Variant =>
            return "end case";
         when Node_Type_Declaration | Node_Private_Extension_Declaration
            | Node_Representation_Clause =>
            return "end record";
         when Node_Task_Type_Declaration | Node_Single_Task_Declaration | Node_Task_Body =>
            return "end task";
         when Node_Protected_Type_Declaration | Node_Single_Protected_Declaration
            | Node_Protected_Body =>
            return "end protected";
         when Node_Package_Declaration | Node_Package_Body =>
            return "end package";
         when Node_Subprogram_Body =>
            return "end subprogram";
         when Node_Entry_Body =>
            return "end entry";
         when Node_Accept_Statement =>
            return "end accept";
         when Node_Declare_Block | Node_Begin_Block | Node_Implicit_Begin
            | Node_Exception_Section | Node_Exception_Handler =>
            return "end block";
         when Node_Generic_Declaration =>
            return "declaration after generic formal part";
         when Node_Private_Part =>
            return "end private part";
         when others =>
            return "end";
      end case;
   end Expected_End_Label;

end Editor.Ada_Syntax_Tree.Line_Classifier;
