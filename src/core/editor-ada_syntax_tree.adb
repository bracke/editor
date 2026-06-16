with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Token_Cursor;

package body Editor.Ada_Syntax_Tree is

   pragma Suppress (Overflow_Check);

   function Lower (S : String) return String is
   begin
      return Ada.Strings.Fixed.Translate (S, Ada.Strings.Maps.Constants.Lower_Case_Map);
   end Lower;

   function Trim (S : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (S, Ada.Strings.Both);
   end Trim;

   function Is_Word_Char (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z')
        or else (C >= 'a' and then C <= 'z')
        or else (C >= '0' and then C <= '9')
        or else C = '_';
   end Is_Word_Char;

   function Starts_With (Text, Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Starts_With_Word (Text, Word : String) return Boolean is
      After : Natural;
   begin
      if not Starts_With (Text, Word) then
         return False;
      end if;
      After := Text'First + Word'Length;
      return After > Text'Last or else not Is_Word_Char (Text (After));
   end Starts_With_Word;

   function Contains (Text, Fragment : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Fragment) /= 0;
   end Contains;

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

   function Hash_Text (Text : String) return Natural is
      type Hash_Value is mod 2 ** 64;
      H : Hash_Value := 2166136261;
   begin
      for C of Text loop
         H := H * 16777619 + Hash_Value (Character'Pos (C) + 1);
      end loop;
      return Natural (H mod Hash_Value (Natural'Last));
   end Hash_Text;

   procedure Mix (Tree : in out Tree_Type; Value : Natural) is
      type Hash_Value is mod 2 ** 64;
      Mixed : constant Hash_Value :=
        Hash_Value (Tree.Result_Fingerprint) * 65599 + Hash_Value (Value) + 17;
   begin
      Tree.Result_Fingerprint := Natural (Mixed mod Hash_Value (Natural'Last));
   end Mix;

   procedure Clear (Tree : in out Tree_Type) is
   begin
      Tree.Nodes.Clear;
      Tree.Root_Node := No_Node;
      Tree.Result_Fingerprint := 0;
   end Clear;

   function Add_Node
     (Tree   : in out Tree_Type;
      Kind   : Node_Kind;
      Source_Span  : Source_Range;
      Parent : Node_Id := No_Node;
      Depth  : Natural := 0;
      Label  : String := "") return Node_Id
   is
      Id : constant Node_Id := Node_Id (Natural (Tree.Nodes.Length) + 1);
      Info : Node_Info;
   begin
      Info.Id := Id;
      Info.Kind := Kind;
      Info.Source_Span := Source_Span;
      Info.Parent := Parent;
      Info.Depth := Depth;
      Info.Label := To_Unbounded_String (Label);
      declare
         type Hash_Value is mod 2 ** 64;
         Fingerprint : constant Hash_Value :=
           Hash_Value (Node_Kind'Pos (Kind)) * 1000003
           + Hash_Value (Source_Span.Start_Line) * 1009
           + Hash_Value (Source_Span.Start_Column) * 97
           + Hash_Value (Source_Span.End_Line) * 53
           + Hash_Value (Source_Span.End_Column) * 17
           + Hash_Value (Natural (Parent)) * 13
           + Hash_Value (Depth) * 7
           + Hash_Value (Hash_Text (Label));
      begin
         Info.Fingerprint := Natural (Fingerprint mod Hash_Value (Natural'Last));
      end;
      Tree.Nodes.Append (Info);
      if Tree.Root_Node = No_Node then
         Tree.Root_Node := Id;
      end if;
      Mix (Tree, Info.Fingerprint);
      return Id;
   end Add_Node;

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


   function Strip_Terminator (Text : String) return String;
   function Segment_Before (Text, Marker : String) return String;
   function Segment_After (Text, Marker : String) return String;

   procedure Add_Declaration_Detail_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String;
      Kind   : Node_Kind);

   function End_Target_Text (Code : String) return String is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);

      function Drop_Prefix (Prefix : String) return String is
      begin
         if Clean'Length <= Prefix'Length then
            return "";
         end if;
         return Trim (Clean (Clean'First + Prefix'Length .. Clean'Last));
      end Drop_Prefix;

      Tail : Unbounded_String := Null_Unbounded_String;
   begin
      if not Starts_With_Word (L, "end") then
         return "";
      elsif Starts_With_Word (L, "end if") then
         Tail := To_Unbounded_String (Drop_Prefix ("end if"));
      elsif Starts_With_Word (L, "end case") then
         Tail := To_Unbounded_String (Drop_Prefix ("end case"));
      elsif Starts_With_Word (L, "end loop") then
         Tail := To_Unbounded_String (Drop_Prefix ("end loop"));
      elsif Starts_With_Word (L, "end select") then
         Tail := To_Unbounded_String (Drop_Prefix ("end select"));
      elsif Starts_With_Word (L, "end record") then
         Tail := To_Unbounded_String (Drop_Prefix ("end record"));
      elsif Starts_With_Word (L, "end task") then
         Tail := To_Unbounded_String (Drop_Prefix ("end task"));
      elsif Starts_With_Word (L, "end protected") then
         Tail := To_Unbounded_String (Drop_Prefix ("end protected"));
      elsif Starts_With_Word (L, "end package") then
         Tail := To_Unbounded_String (Drop_Prefix ("end package"));
      elsif Starts_With_Word (L, "end procedure") then
         Tail := To_Unbounded_String (Drop_Prefix ("end procedure"));
      elsif Starts_With_Word (L, "end function") then
         Tail := To_Unbounded_String (Drop_Prefix ("end function"));
      else
         Tail := To_Unbounded_String (Drop_Prefix ("end"));
      end if;

      declare
         Work : constant String := Trim (To_String (Tail));
      begin
         if Work = "" then
            return "";
         elsif Contains (Work, ";") then
            return Segment_Before (Work, ";");
         else
            return Work;
         end if;
      end;
   end End_Target_Text;

   function Opening_Target_Text (Kind : Node_Kind; Label : String) return String is
      Clean : constant String :=
        (if Kind = Node_Expected_Token then Trim (Label) else Strip_Terminator (Label));
      L     : constant String := Lower (Clean);

      function After_Prefix (Prefix : String) return String is
      begin
         if Clean'Length <= Prefix'Length then
            return "";
         end if;
         return Trim (Clean (Clean'First + Prefix'Length .. Clean'Last));
      end After_Prefix;

      function First_Name (Text : String) return String is
         Work : constant String := Trim (Text);
         L_Work : constant String := Lower (Work);
      begin
         if Work = "" then
            return "";
         elsif Contains (Work, "(") then
            return Segment_Before (Work, "(");
         elsif Contains (Work, ":") then
            return Segment_Before (Work, ":");
         elsif Contains (L_Work, " return ") then
            return Segment_Before (Work, " return " );
         elsif Contains (L_Work, " is ") then
            return Segment_Before (Work, " is " );
         elsif Work'Length > 3
           and then L_Work (L_Work'Last - 2 .. L_Work'Last) = " is"
         then
            return Trim (Work (Work'First .. Work'Last - 3));
         elsif Contains (Work, ";") then
            return Segment_Before (Work, ";");
         else
            return Work;
         end if;
      end First_Name;
   begin
      case Kind is
         when Node_Package_Body =>
            if Starts_With_Word (L, "package body") then
               return First_Name (After_Prefix ("package body"));
            end if;
         when Node_Package_Declaration =>
            if Starts_With_Word (L, "package") then
               return First_Name (After_Prefix ("package"));
            end if;
         when Node_Subprogram_Body =>
            if Starts_With_Word (L, "procedure") then
               return First_Name (After_Prefix ("procedure"));
            elsif Starts_With_Word (L, "function") then
               return First_Name (After_Prefix ("function"));
            end if;
         when Node_Task_Body =>
            return First_Name (After_Prefix ("task body"));
         when Node_Task_Type_Declaration =>
            return First_Name (After_Prefix ("task type"));
         when Node_Single_Task_Declaration =>
            return First_Name (After_Prefix ("task"));
         when Node_Protected_Body =>
            return First_Name (After_Prefix ("protected body"));
         when Node_Protected_Type_Declaration =>
            return First_Name (After_Prefix ("protected type"));
         when Node_Single_Protected_Declaration =>
            return First_Name (After_Prefix ("protected"));
         when Node_Entry_Body =>
            return First_Name (After_Prefix ("entry"));
         when Node_Accept_Statement =>
            return First_Name (After_Prefix ("accept"));
         when Node_Loop_Statement =>
            if Contains (L, " loop") then
               return Segment_Before (Clean, " loop");
            end if;
         when others =>
            null;
      end case;
      return "";
   end Opening_Target_Text;

   function Same_Ada_Name (Left : String; Right : String) return Boolean is
   begin
      return Lower (Trim (Left)) = Lower (Trim (Right));
   end Same_Ada_Name;

   function End_Matches_Kind (Opener : Node_Kind; End_Code : String) return Boolean is
      L : constant String := Lower (End_Code);
   begin
      if Starts_With_Word (L, "end if") then
         return Opener = Node_If_Statement
           or else Opener = Node_Elsif_Part
           or else Opener = Node_Else_Part;
      elsif Starts_With_Word (L, "end case") then
         return Opener = Node_Case_Statement
           or else Opener = Node_When_Alternative
           or else Opener = Node_Variant_Part
           or else Opener = Node_Variant;
      elsif Starts_With_Word (L, "end loop") then
         return Opener = Node_Loop_Statement;
      elsif Starts_With_Word (L, "end select") then
         return Opener = Node_Select_Statement
           or else Opener = Node_Select_Alternative;
      elsif Starts_With_Word (L, "end record") then
         return Opener = Node_Type_Declaration
           or else Opener = Node_Private_Extension_Declaration
           or else Opener = Node_Representation_Clause;
      elsif Starts_With_Word (L, "end task") then
         return Opener = Node_Task_Type_Declaration
           or else Opener = Node_Single_Task_Declaration
           or else Opener = Node_Task_Body;
      elsif Starts_With_Word (L, "end protected") then
         return Opener = Node_Protected_Type_Declaration
           or else Opener = Node_Single_Protected_Declaration
           or else Opener = Node_Protected_Body;
      elsif Starts_With_Word (L, "end") then
         --  Ada permits a plain `end Name;` for packages, subprograms,
         --  accept statements, declare blocks, and bodies.  Treat it as a
         --  grammar boundary for any non-special opener; the named target is
         --  retained in the end node label, while mismatch recovery above
         --  handles the special compound endings.
         return Opener = Node_Package_Declaration
           or else Opener = Node_Package_Body
           or else Opener = Node_Subprogram_Body
           or else Opener = Node_Task_Body
           or else Opener = Node_Protected_Body
           or else Opener = Node_Entry_Body
           or else Opener = Node_Accept_Statement
           or else Opener = Node_Declare_Block
           or else Opener = Node_Begin_Block
           or else Opener = Node_Implicit_Begin
           or else Opener = Node_Exception_Section
           or else Opener = Node_Exception_Handler;
      end if;
      return False;
   end End_Matches_Kind;

   function Alternative_Has_Grammar_Owner
     (Alternative : Node_Kind;
      Owner       : Node_Kind) return Boolean
   is
   begin
      case Alternative is
         when Node_Elsif_Part | Node_Else_Part =>
            return Owner = Node_If_Statement
              or else Owner = Node_Elsif_Part
              or else Owner = Node_Else_Part;
         when Node_When_Alternative =>
            return Owner = Node_Case_Statement
              or else Owner = Node_When_Alternative;
         when Node_Select_Alternative =>
            return Owner = Node_Select_Statement
              or else Owner = Node_Select_Alternative;
         when Node_Exception_Section =>
            return Owner = Node_Begin_Block
              or else Owner = Node_Subprogram_Body
              or else Owner = Node_Package_Body
              or else Owner = Node_Task_Body
              or else Owner = Node_Protected_Body
              or else Owner = Node_Entry_Body
              or else Owner = Node_Accept_Statement;
         when Node_Exception_Handler =>
            return Owner = Node_Exception_Section
              or else Owner = Node_Exception_Handler;
         when Node_Variant =>
            return Owner = Node_Variant_Part
              or else Owner = Node_Variant;
         when others =>
            return True;
      end case;
   end Alternative_Has_Grammar_Owner;


   function Is_Transient_Statement_Part (Kind : Node_Kind) return Boolean is
   begin
      return Kind = Node_Begin_Block
        or else Kind = Node_Implicit_Begin
        or else Kind = Node_Exception_Section
        or else Kind = Node_Exception_Handler;
   end Is_Transient_Statement_Part;

   function End_Implicitly_Closes_Statement_Part
     (Transient : Node_Kind;
      Owner     : Node_Kind;
      End_Code  : String) return Boolean
   is
      L : constant String := Lower (End_Code);
   begin
      if Transient = Node_Private_Part then
         return Owner = Node_Package_Declaration
           or else Owner = Node_Task_Type_Declaration
           or else Owner = Node_Single_Task_Declaration
           or else Owner = Node_Protected_Type_Declaration
           or else Owner = Node_Single_Protected_Declaration;
      elsif not Is_Transient_Statement_Part (Transient) then
         return False;
      end if;

      if Starts_With_Word (L, "end if")
        or else Starts_With_Word (L, "end case")
        or else Starts_With_Word (L, "end loop")
        or else Starts_With_Word (L, "end select")
        or else Starts_With_Word (L, "end record")
      then
         return False;
      end if;

      return Owner = Node_Package_Body
        or else Owner = Node_Subprogram_Body
        or else Owner = Node_Task_Body
        or else Owner = Node_Protected_Body
        or else Owner = Node_Entry_Body
        or else Owner = Node_Accept_Statement
        or else Owner = Node_Declare_Block;
   end End_Implicitly_Closes_Statement_Part;


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

   function If_Condition_Text (Code, Prefix : String) return String is
      Clean : constant String := Trim (Code);
      L     : constant String := Lower (Clean);
      Start : Natural := Clean'First + Prefix'Length;
      Then_Pos : Natural := 0;
   begin
      while Start <= Clean'Last and then Clean (Start) = ' ' loop
         Start := Start + 1;
      end loop;

      for I in Clean'Range loop
         if I + 4 <= Clean'Last
           and then L (I .. I + 4) = " then"
           and then (I + 5 > Clean'Last or else not Is_Word_Char (L (I + 5)))
         then
            Then_Pos := I;
         end if;
      end loop;

      if Then_Pos = 0 or else Then_Pos <= Start then
         return "";
      end if;

      return Trim (Clean (Start .. Then_Pos - 1));
   end If_Condition_Text;

   function If_Action_Text (Code : String) return String is
      Clean : constant String := Trim (Code);
      L     : constant String := Lower (Clean);
      Then_Pos : Natural := 0;
   begin
      for I in Clean'Range loop
         if I + 4 <= Clean'Last
           and then L (I .. I + 4) = " then"
           and then (I + 5 > Clean'Last or else not Is_Word_Char (L (I + 5)))
         then
            Then_Pos := I;
         end if;
      end loop;

      if Then_Pos = 0 or else Then_Pos + 5 > Clean'Last then
         return "";
      end if;

      return Trim (Clean (Then_Pos + 5 .. Clean'Last));
   end If_Action_Text;

   function Is_Character_Literal_At
     (Text : String; Pos : Natural; Last : Natural) return Boolean
   is
   begin
      return Pos + 2 <= Last
        and then Text (Pos) = Character'Val (39)
        and then Text (Pos + 2) = Character'Val (39);
   end Is_Character_Literal_At;



   function Code_Preserving_Literals_For_Retention (Line : String) return String is
      In_String : Boolean := False;
      I         : Natural := Line'First;
   begin
      --  Syntax classification still uses the generic sanitized line, but
      --  retained pragma argument nodes need literal text.  Operator-symbol
      --  pragma targets and pragma string arguments are semantically relevant
      --  to the bounded language model, so strip comments while preserving
      --  Ada string and character literals for syntax-tree children.
      while I <= Line'Last loop
         if In_String then
            if Line (I) = '"' then
               if I + 1 <= Line'Last and then Line (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Character_Literal_At (Line, I, Line'Last) then
            I := I + 2;
         elsif Line (I) = '"' then
            In_String := True;
         elsif Line (I) = '-'
           and then I + 1 <= Line'Last
           and then Line (I + 1) = '-'
         then
            if I = Line'First then
               return "";
            else
               return Line (Line'First .. I - 1);
            end if;
         end if;
         I := I + 1;
      end loop;

      return Line;
   end Code_Preserving_Literals_For_Retention;

   function Segment_Between_First_Parens (Text : String) return String is
      Open_Pos  : Natural := 0;
      Close_Pos : Natural := 0;
      Level     : Natural := 0;
      In_String : Boolean := False;
      I         : Natural := Text'First;
   begin
      --  This helper is used for retained syntax-tree children such as
      --  pragma arguments and generic actuals.  It must find the balancing
      --  close parenthesis of the outer construct, not a parenthesis that
      --  happens to occur inside a string or character literal.
      while I <= Text'Last loop
         if In_String then
            if Text (I) = '"' then
               if I + 1 <= Text'Last and then Text (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Character_Literal_At (Text, I, Text'Last) then
            I := I + 2;
         elsif Text (I) = '"' then
            In_String := True;
         elsif Text (I) = '(' then
            if Open_Pos = 0 then
               Open_Pos := I;
            end if;
            Level := Level + 1;
         elsif Text (I) = ')' and then Level > 0 then
            Level := Level - 1;
            if Level = 0 then
               Close_Pos := I;
               exit;
            end if;
         end if;
         I := I + 1;
      end loop;

      if Open_Pos = 0 or else Close_Pos = 0 or else Close_Pos <= Open_Pos + 1 then
         return "";
      end if;
      return Trim (Text (Open_Pos + 1 .. Close_Pos - 1));
   end Segment_Between_First_Parens;

   function Segment_Between_First_Parens_After
     (Text   : String;
      Marker : String) return String
   is
      L : constant String := Lower (Text);
   begin
      for I in L'Range loop
         if I + Marker'Length - 1 <= L'Last
           and then L (I .. I + Marker'Length - 1) = Marker
         then
            if I + Marker'Length <= Text'Last then
               return Segment_Between_First_Parens
                 (Text (I + Marker'Length .. Text'Last));
            end if;
            return "";
         end if;
      end loop;

      return "";
   end Segment_Between_First_Parens_After;

   function Strip_Leading_With (Text : String) return String is
      T : constant String := Trim (Text);
      L : constant String := Lower (T);
   begin
      if Starts_With_Word (L, "with") then
         if T'Length <= 4 then
            return "";
         end if;
         return Trim (T (T'First + 4 .. T'Last));
      end if;
      return T;
   end Strip_Leading_With;

   function Top_Level_Arrow_Position (Text : String) return Natural is
      Level     : Natural := 0;
      In_String : Boolean := False;
      I         : Natural := Text'First;
   begin
      if Text'Length < 2 then
         return 0;
      end if;

      while I <= Text'Last - 1 loop
         if In_String then
            if Text (I) = '"' then
               if I + 1 <= Text'Last and then Text (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Character_Literal_At (Text, I, Text'Last) then
            I := I + 2;
         elsif Text (I) = '"' then
            In_String := True;
         elsif Text (I) = '(' then
            Level := Level + 1;
         elsif Text (I) = ')' and then Level > 0 then
            Level := Level - 1;
         elsif Text (I) = '=' and then Text (I + 1) = '>' and then Level = 0 then
            return I;
         end if;
         I := I + 1;
      end loop;
      return 0;
   end Top_Level_Arrow_Position;

   function Has_Top_Level_Arrow (Text : String) return Boolean is
   begin
      return Top_Level_Arrow_Position (Text) /= 0;
   end Has_Top_Level_Arrow;

   function Split_Before_Top_Level_Arrow (Text : String) return String is
      Arrow : constant Natural := Top_Level_Arrow_Position (Text);
   begin
      if Arrow = 0 then
         return Trim (Text);
      elsif Arrow = Text'First then
         return "";
      else
         return Trim (Text (Text'First .. Arrow - 1));
      end if;
   end Split_Before_Top_Level_Arrow;

   function Split_After_Top_Level_Arrow (Text : String) return String is
      Arrow : constant Natural := Top_Level_Arrow_Position (Text);
   begin
      if Arrow = 0 or else Arrow + 2 > Text'Last then
         return "";
      else
         return Trim (Text (Arrow + 2 .. Text'Last));
      end if;
   end Split_After_Top_Level_Arrow;

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
         Ignored := Add_Node (Tree, Kind, (Line, 1, Line, Last_Column), Parent, Depth, Clean);
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

      Expr := Add_Node (Tree, Node_Expression, (Line, 1, Line, Last_Column), Parent, Depth, Clean);

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
               Id := Add_Node
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
            Id := Add_Node
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

   procedure Add_Association_List_Nodes
     (Tree             : in out Tree_Type;
      Parent           : Node_Id;
      Depth            : Natural;
      Line             : Positive;
      Text             : String;
      Association_Kind : Node_Kind)
   is
      Clean     : constant String := Strip_Terminator (Text);
      Start     : Natural;
      Level     : Natural := 0;
      In_String : Boolean := False;
      I         : Natural;

      procedure Add_Association (Raw : String) is
         Segment : constant String := Strip_Terminator (Raw);
         Assoc   : Node_Id;

         procedure Add_Key_Value_Details
           (Key_Node   : Node_Kind;
            Value_Node : Node_Kind)
         is
            Key   : constant String := Split_Before_Top_Level_Arrow (Segment);
            Value : constant String := Split_After_Top_Level_Arrow (Segment);
         begin
            if Has_Top_Level_Arrow (Segment) then
               Add_Detail_Node (Tree, Assoc, Depth + 1, Line, Key_Node, Key);
               Add_Detail_Node (Tree, Assoc, Depth + 1, Line, Value_Node, Value);
            else
               Add_Detail_Node (Tree, Assoc, Depth + 1, Line, Value_Node, Segment);
            end if;
         end Add_Key_Value_Details;
      begin
         if Segment = "" then
            return;
         end if;

         Assoc := Add_Node
           (Tree, Association_Kind, (Line, 1, Line, Last_Column_For (Segment)),
            Parent, Depth, Segment);

         case Association_Kind is
            when Node_Aspect_Association =>
               Add_Key_Value_Details (Node_Aspect_Name, Node_Aspect_Value);
            when Node_Generic_Actual_Association =>
               Add_Key_Value_Details (Node_Generic_Actual_Formal, Node_Generic_Actual_Value);
               if Has_Top_Level_Arrow (Segment) then
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Statement_Target,
                     Split_Before_Top_Level_Arrow (Segment));
               end if;
            when Node_Discriminant_Specification | Node_Parameter_Specification =>
               Add_Declaration_Detail_Nodes (Tree, Assoc, Depth + 1, Line, Segment, Association_Kind);
            when Node_Pragma_Argument =>
               if Has_Top_Level_Arrow (Segment) then
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Pragma_Argument_Association, Segment);
                  Add_Key_Value_Details (Node_Statement_Target, Node_Statement_Action);
               else
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Statement_Arguments, Segment);
               end if;
            when others =>
               if Has_Top_Level_Arrow (Segment) then
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Statement_Target,
                     Split_Before_Top_Level_Arrow (Segment));
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Statement_Action,
                     Split_After_Top_Level_Arrow (Segment));
               else
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Statement_Target, Segment);
               end if;
         end case;
      end Add_Association;
   begin
      if Clean = "" then
         return;
      end if;

      Start := Clean'First;
      I := Clean'First;
      while I <= Clean'Last loop
         if In_String then
            if Clean (I) = '"' then
               if I + 1 <= Clean'Last and then Clean (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Character_Literal_At (Clean, I, Clean'Last) then
            I := I + 2;
         elsif Clean (I) = '"' then
            In_String := True;
         elsif Clean (I) = '(' then
            Level := Level + 1;
         elsif Clean (I) = ')' and then Level > 0 then
            Level := Level - 1;
         elsif Clean (I) = ',' and then Level = 0 then
            if I > Start then
               Add_Association (Clean (Start .. I - 1));
            end if;
            Start := I + 1;
         end if;
         I := I + 1;
      end loop;

      if Start <= Clean'Last then
         Add_Association (Clean (Start .. Clean'Last));
      end if;
   end Add_Association_List_Nodes;

   function Declaration_Name_Text (Code : String; Lead_Word : String := "") return String is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);

      function Drop_First (Count : Natural) return String is
      begin
         if Count >= Clean'Length then
            return "";
         end if;
         return Trim (Clean (Clean'First + Count .. Clean'Last));
      end Drop_First;

      Tail : Unbounded_String := To_Unbounded_String (Clean);
   begin
      if Lead_Word /= "" and then Starts_With_Word (L, Lead_Word) then
         Tail := To_Unbounded_String (Drop_First (Lead_Word'Length));
      elsif Starts_With_Word (L, "task type") then
         Tail := To_Unbounded_String (Drop_First (9));
      elsif Starts_With_Word (L, "task body") then
         Tail := To_Unbounded_String (Drop_First (9));
      elsif Starts_With_Word (L, "task") then
         Tail := To_Unbounded_String (Drop_First (4));
      elsif Starts_With_Word (L, "protected type") then
         Tail := To_Unbounded_String (Drop_First (14));
      elsif Starts_With_Word (L, "protected body") then
         Tail := To_Unbounded_String (Drop_First (14));
      elsif Starts_With_Word (L, "protected") then
         Tail := To_Unbounded_String (Drop_First (9));
      elsif Starts_With_Word (L, "entry") then
         Tail := To_Unbounded_String (Drop_First (5));
      end if;

      declare
         Work : constant String := To_String (Tail);
      begin
         if Contains (Work, ":") then
            return Segment_Before (Work, ":");
         elsif Contains (Work, " is ") then
            return Segment_Before (Work, " is ");
         elsif Contains (Work, " renames ") then
            return Segment_Before (Work, " renames ");
         elsif Contains (Work, "(") then
            return Segment_Before (Work, "(");
         elsif Contains (Work, ";") then
            return Segment_Before (Work, ";");
         else
            return Trim (Work);
         end if;
      end;
   end Declaration_Name_Text;

   function Subprogram_Name_Text (Code : String) return String is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);
      Work  : Unbounded_String := To_Unbounded_String (Clean);
   begin
      if Starts_With_Word (L, "function") and then Clean'Length > 8 then
         Work := To_Unbounded_String (Trim (Clean (Clean'First + 8 .. Clean'Last)));
      elsif Starts_With_Word (L, "procedure") and then Clean'Length > 9 then
         Work := To_Unbounded_String (Trim (Clean (Clean'First + 9 .. Clean'Last)));
      end if;

      declare
         Tail : constant String := To_String (Work);
      begin
         if Contains (Tail, "(") then
            return Segment_Before (Tail, "(");
         elsif Contains (Lower (Tail), " return ") then
            return Segment_Before (Tail, " return ");
         elsif Contains (Lower (Tail), " is ") then
            return Segment_Before (Tail, " is ");
         elsif Contains (Tail, ";") then
            return Segment_Before (Tail, ";");
         else
            return Trim (Tail);
         end if;
      end;
   end Subprogram_Name_Text;

   function Subprogram_Profile_Text (Code : String) return String is
      Clean : constant String := Strip_Terminator (Code);
   begin
      if Contains (Clean, "(") then
         return Segment_Between_First_Parens (Clean);
      else
         return "";
      end if;
   end Subprogram_Profile_Text;

   function Subprogram_Result_Text (Code : String) return String is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);
      Tail  : Unbounded_String := Null_Unbounded_String;
   begin
      if not Starts_With_Word (L, "function") or else not Contains (L, " return ") then
         return "";
      end if;

      Tail := To_Unbounded_String (Segment_After (Clean, "return"));
      declare
         Work : constant String := To_String (Tail);
      begin
         if Contains (Lower (Work), " is ") then
            return Trim (Segment_Before (Work, " is "));
         elsif Contains (Work, " with ") then
            return Trim (Segment_Before (Work, " with "));
         elsif Contains (Work, ";") then
            return Trim (Segment_Before (Work, ";"));
         else
            return Trim (Work);
         end if;
      end;
   end Subprogram_Result_Text;

   procedure Add_Declaration_Detail_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String;
      Kind   : Node_Kind)
   is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);
      Name  : Unbounded_String := Null_Unbounded_String;
      After_Colon : Unbounded_String := Null_Unbounded_String;
   begin
      case Kind is
         when Node_Package_Declaration | Node_Package_Body |
              Node_Rename_Declaration | Node_Instantiation =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean, "package"));
         when Node_Subprogram_Declaration | Node_Subprogram_Body |
              Node_Abstract_Subprogram_Declaration |
              Node_Null_Procedure_Declaration |
              Node_Expression_Function_Declaration |
              Node_Formal_Subprogram_Declaration | Node_Body_Stub =>
            if Starts_With_Word (L, "function")
              or else Starts_With_Word (L, "procedure")
            then
               Name := To_Unbounded_String (Subprogram_Name_Text (Clean));
            else
               Name := To_Unbounded_String (Declaration_Name_Text (Clean));
            end if;
         when Node_Type_Declaration | Node_Incomplete_Type_Declaration |
              Node_Private_Extension_Declaration | Node_Formal_Type_Declaration =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean, "type"));
         when Node_Subtype_Declaration =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean, "subtype"));
         when Node_Task_Declaration | Node_Task_Type_Declaration |
              Node_Single_Task_Declaration | Node_Task_Body |
              Node_Protected_Declaration | Node_Protected_Type_Declaration |
              Node_Single_Protected_Declaration | Node_Protected_Body |
              Node_Entry_Declaration | Node_Entry_Body | Node_Entry_Body_Stub =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean));
         when Node_Object_Declaration | Node_Constant_Declaration |
              Node_Deferred_Constant_Declaration | Node_Number_Declaration |
              Node_Component_Declaration | Node_Discriminant_Specification |
              Node_Parameter_Specification | Node_Formal_Object_Declaration |
              Node_Exception_Declaration =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean));
         when Node_Formal_Package_Declaration =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean, "with package"));
         when Node_Choice_Parameter_Specification =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean, "when"));
         when Node_Enumeration_Literal_Declaration =>
            Name := To_Unbounded_String (Clean);
         when others =>
            null;
      end case;

      if To_String (Name) /= "" then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Name, To_String (Name));
      end if;

      if Kind = Node_Subprogram_Declaration
        or else Kind = Node_Subprogram_Body
        or else Kind = Node_Abstract_Subprogram_Declaration
        or else Kind = Node_Null_Procedure_Declaration
        or else Kind = Node_Expression_Function_Declaration
        or else Kind = Node_Formal_Subprogram_Declaration
        or else Kind = Node_Body_Stub
      then
         Add_Detail_Node
           (Tree, Parent, Depth, Line, Node_Declaration_Profile,
            Subprogram_Profile_Text (Clean));
         Add_Detail_Node
           (Tree, Parent, Depth, Line, Node_Declaration_Result,
            Subprogram_Result_Text (Clean));
      end if;

      if Kind = Node_Rename_Declaration and then Contains (L, " renames ") then
         Add_Detail_Node
           (Tree, Parent, Depth, Line, Node_Declaration_Target,
            Segment_After (Clean, "renames"));
      end if;

      if Kind = Node_Entry_Body then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Profile,
                          Segment_Between_First_Parens (Clean));
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Statement_Condition,
                          Segment_Before (Segment_After (Clean, "when"), "is"));
      elsif Kind = Node_Entry_Body_Stub then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Profile,
                          Segment_Between_First_Parens (Clean));
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "entry body stub");
      end if;

      if Kind = Node_Abstract_Subprogram_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "abstract");
      elsif Kind = Node_Null_Procedure_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "null procedure");
      elsif Kind = Node_Expression_Function_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "expression function");
      elsif Kind = Node_Constant_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "constant");
      elsif Kind = Node_Deferred_Constant_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "deferred constant");
      elsif Kind = Node_Number_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "named number");
      elsif Kind = Node_Task_Type_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "task type");
      elsif Kind = Node_Single_Task_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "single task");
      elsif Kind = Node_Protected_Type_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "protected type");
      elsif Kind = Node_Single_Protected_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "single protected");
      end if;

      if Kind = Node_Subprogram_Declaration
        or else Kind = Node_Subprogram_Body
        or else Kind = Node_Abstract_Subprogram_Declaration
        or else Kind = Node_Null_Procedure_Declaration
        or else Kind = Node_Expression_Function_Declaration
        or else Kind = Node_Formal_Subprogram_Declaration
        or else Kind = Node_Body_Stub
        or else Kind = Node_Entry_Body
        or else Kind = Node_Entry_Body_Stub
      then
         null;
      elsif Contains (Clean, ":") then
         After_Colon := To_Unbounded_String (Trim (Segment_After (Clean, ":")));
         if Contains (To_String (After_Colon), ":=") then
            Add_Detail_Node
              (Tree, Parent, Depth, Line, Node_Declaration_Subtype,
               Segment_Before (To_String (After_Colon), ":="));
            Add_Detail_Node
              (Tree, Parent, Depth, Line, Node_Declaration_Default,
               Segment_After (To_String (After_Colon), ":="));
         elsif To_String (After_Colon) /= "" then
            Add_Detail_Node
              (Tree, Parent, Depth, Line, Node_Declaration_Subtype, To_String (After_Colon));
         end if;
      elsif Contains (L, " is ") then
         Add_Detail_Node
           (Tree, Parent, Depth, Line, Node_Declaration_Subtype,
            Segment_After (Clean, " is "));
      end if;

      if Kind = Node_Subprogram_Declaration
        or else Kind = Node_Subprogram_Body
        or else Kind = Node_Abstract_Subprogram_Declaration
        or else Kind = Node_Null_Procedure_Declaration
        or else Kind = Node_Expression_Function_Declaration
        or else Kind = Node_Formal_Subprogram_Declaration
        or else Kind = Node_Body_Stub
        or else Kind = Node_Entry_Body
        or else Kind = Node_Entry_Body_Stub
      then
         null;
      elsif Contains (L, " in out ") then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "in out");
      elsif Contains (L, " out ") then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "out");
      elsif Contains (L, " in ") then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "in");
      elsif Contains (L, " access ") or else Starts_With_Word (L, "access") then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "access");
      end if;
   end Add_Declaration_Detail_Nodes;

   procedure Add_Discriminant_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String)
   is
      Inside : constant String := Segment_Between_First_Parens (Code);
   begin
      if Inside /= "" and then Contains (Inside, ":") then
         Add_Association_List_Nodes
           (Tree, Parent, Depth, Line, Inside, Node_Discriminant_Specification);
      end if;
   end Add_Discriminant_Nodes;



   procedure Add_Enumeration_Literal_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String)
   is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);
      Items : constant String := Segment_Between_First_Parens_After (Clean, " is ");
      Start : Natural;
      Level : Natural := 0;

      function Looks_Like_Enumeration_Type return Boolean is
      begin
         return Starts_With_Word (L, "type")
           and then Contains (L, " is ")
           and then Items /= ""
           and then not Contains (L, " range ")
           and then not Contains (L, " digits ")
           and then not Contains (L, " delta ")
           and then not Contains (L, " access ")
           and then not Contains (L, " array ")
           and then not Contains (L, " record")
           and then not Contains (L, " interface")
           and then not Contains (L, " private");
      end Looks_Like_Enumeration_Type;

      procedure Add_Item (Raw : String) is
         Item : constant String := Trim (Raw);
      begin
         if Item /= "" then
            declare
               Ignored : constant Node_Id := Add_Node
                 (Tree, Node_Enumeration_Literal_Declaration,
                  (Line, 1, Line, Last_Column_For (Item)), Parent, Depth, Item);
            begin
               null;
            end;
         end if;
      end Add_Item;
   begin
      if not Looks_Like_Enumeration_Type then
         return;
      end if;

      Start := Items'First;
      for I in Items'Range loop
         if Items (I) = '(' then
            Level := Level + 1;
         elsif Items (I) = ')' and then Level > 0 then
            Level := Level - 1;
         elsif Items (I) = ',' and then Level = 0 then
            if I > Start then
               Add_Item (Items (Start .. I - 1));
            end if;
            Start := I + 1;
         end if;
      end loop;
      if Start <= Items'Last then
         Add_Item (Items (Start .. Items'Last));
      end if;
   end Add_Enumeration_Literal_Nodes;

   procedure Add_Aspect_Specification_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Tail : constant String := Strip_Leading_With (Segment_After (Text, "with"));
      Spec : Node_Id;
   begin
      if Tail = "" then
         return;
      end if;

      Spec := Add_Node
        (Tree, Node_Aspect_Specification, (Line, 1, Line, Last_Column_For (Tail)),
         Parent, Depth, Tail);
      Add_Association_List_Nodes
        (Tree, Spec, Depth + 1, Line, Tail, Node_Aspect_Association);
   end Add_Aspect_Specification_Nodes;

   procedure Add_Generic_Actual_Part_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Actuals : constant String := Segment_Between_First_Parens (Text);
      Part    : Node_Id;
   begin
      if Actuals = "" then
         return;
      end if;

      Part := Add_Node
        (Tree, Node_Generic_Actual_Part,
         (Line, 1, Line, Last_Column_For (Actuals)), Parent, Depth, Actuals);
      Add_Association_List_Nodes
        (Tree, Part, Depth + 1, Line, Actuals, Node_Generic_Actual_Association);
   end Add_Generic_Actual_Part_Nodes;

   procedure Add_Representation_Clause_Detail_Nodes
     (Tree   : in out Tree_Type;
      Clause : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Clean  : constant String := Strip_Terminator (Text);
      L      : constant String := Lower (Clean);
      Target : Ada.Strings.Unbounded.Unbounded_String := Null_Unbounded_String;
      Item   : Ada.Strings.Unbounded.Unbounded_String := Null_Unbounded_String;
   begin
      if Clean = "" then
         return;
      end if;

      if Starts_With_Word (L, "for") and then Contains (L, " use ") then
         Target := To_Unbounded_String (Segment_Before (Segment_After (Clean, "for"), "use"));
         Item := To_Unbounded_String (Segment_After (Clean, "use"));
      elsif Starts_With_Word (L, "for") and then Contains (L, " at ") then
         Target := To_Unbounded_String (Segment_Before (Segment_After (Clean, "for"), "at"));
         Item := To_Unbounded_String (Segment_After (Clean, "at"));
      end if;

      Add_Detail_Node
        (Tree, Clause, Depth, Line, Node_Representation_Target, To_String (Target));
      Add_Detail_Node
        (Tree, Clause, Depth, Line, Node_Representation_Item, To_String (Item));

      declare
         Item_Text : constant String := To_String (Item);
      begin
         if Contains (Item_Text, "=>")
           or else (Item_Text /= "" and then Item_Text (Item_Text'First) = '(')
         then
            declare
               Assocs : constant String :=
                 (if Segment_Between_First_Parens (Item_Text) /= "" then
                     Segment_Between_First_Parens (Item_Text)
                  else
                     Item_Text);
            begin
               --  Enumeration representation clauses are aggregate-shaped.
               --  Keep both named and positional aggregate associations so the
               --  semantic projection can map positional values to the retained
               --  enumeration literal order instead of losing them as opaque
               --  item text.
               Add_Association_List_Nodes
                 (Tree, Clause, Depth, Line, Assocs, Node_Named_Association);
            end;
         end if;
      end;
   end Add_Representation_Clause_Detail_Nodes;

   procedure Add_Representation_Component_Clause_Detail_Nodes
     (Tree   : in out Tree_Type;
      Clause : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Clean    : constant String := Strip_Terminator (Text);
      Target   : constant String := Segment_Before (Clean, "at");
      Location : constant String := Segment_Before (Segment_After (Clean, "at"), "range");
      Bits     : constant String := Segment_After (Clean, "range");
   begin
      if Clean = "" then
         return;
      end if;

      Add_Detail_Node
        (Tree, Clause, Depth, Line, Node_Representation_Target, Target);
      Add_Detail_Node
        (Tree, Clause, Depth, Line, Node_Representation_Item, "at " & Location);
      Add_Detail_Node
        (Tree, Clause, Depth, Line, Node_Range_Expression, Bits);
   end Add_Representation_Component_Clause_Detail_Nodes;

   procedure Add_Representation_Clause_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Clean  : constant String := Strip_Terminator (Text);
      Clause : Node_Id;
   begin
      if Clean = "" then
         return;
      end if;

      Clause := Add_Node
        (Tree, Node_Representation_Clause,
         (Line, 1, Line, Last_Column_For (Clean)), Parent, Depth, Clean);
      Add_Representation_Clause_Detail_Nodes
        (Tree, Clause, Depth + 1, Line, Clean);
   end Add_Representation_Clause_Nodes;

   function First_Semicolon (Text : String) return Natural is
   begin
      for I in Text'Range loop
         if Text (I) = ';' then
            return I;
         end if;
      end loop;
      return 0;
   end First_Semicolon;

   function Statement_Node_Kind (Text : String) return Node_Kind is
      T : constant String := Trim (Text);
      L : constant String := Lower (T);
   begin
      if Starts_With_Word (L, "if") then
         return Node_If_Statement;
      elsif Starts_With_Word (L, "elsif") then
         return Node_Elsif_Part;
      elsif Starts_With_Word (L, "else") then
         return Node_Else_Part;
      elsif Starts_With_Word (L, "case") then
         return Node_Case_Statement;
      elsif Starts_With_Word (L, "when") then
         return Node_When_Alternative;
      elsif Starts_With_Word (L, "or") then
         return Node_Select_Alternative;
      elsif Starts_With_Word (L, "loop")
        or else Starts_With_Word (L, "while")
        or else Starts_With_Word (L, "for")
      then
         return Node_Loop_Statement;
      elsif Starts_With_Word (L, "declare") then
         return Node_Declare_Block;
      elsif Starts_With_Word (L, "begin") then
         return Node_Begin_Block;
      elsif Starts_With_Word (L, "select") then
         return Node_Select_Statement;
      elsif Starts_With_Word (L, "then") and then Contains (L, "then abort") then
         return Node_Select_Alternative;
      elsif Starts_With_Word (L, "exception") then
         return Node_Exception_Section;
      elsif Starts_With_Word (L, "accept") then
         return Node_Accept_Statement;
      elsif Starts_With_Word (L, "pragma") then
         return Node_Pragma_Statement;
      elsif Starts_With_Word (L, "null") then
         return Node_Null_Statement;
      elsif Starts_With_Word (L, "return") then
         return Node_Return_Statement;
      elsif Starts_With_Word (L, "raise") then
         return Node_Raise_Statement;
      elsif Starts_With_Word (L, "exit") then
         return Node_Exit_Statement;
      elsif Starts_With_Word (L, "goto") then
         return Node_Goto_Statement;
      elsif Starts_With_Word (L, "delay") then
         return Node_Delay_Statement;
      elsif Starts_With_Word (L, "requeue") then
         return Node_Requeue_Statement;
      elsif Starts_With_Word (L, "abort") then
         return Node_Abort_Statement;
      elsif Starts_With_Word (L, "terminate") then
         return Node_Terminate_Statement;
      elsif Contains (T, ":=") then
         return Node_Assignment_Statement;
      elsif Contains (T, "(") or else Contains (T, ";") or else T /= "" then
         return Node_Call_Statement;
      else
         return Node_Unknown;
      end if;
   end Statement_Node_Kind;

   procedure Attach_Statement_Details
     (Tree           : in out Tree_Type;
      Stmt           : Node_Id;
      Kind           : Node_Kind;
      Depth          : Natural;
      Line           : Positive;
      Text           : String;
      Is_Alternative : Boolean := False)
   is
      Clean : constant String := Strip_Terminator (Text);
      L     : constant String := Lower (Clean);
      Tail  : constant String :=
        (case Kind is
            when Node_Return_Statement  => Segment_After (Clean, "return"),
            when Node_Raise_Statement   => Segment_After (Clean, "raise"),
            when Node_Exit_Statement    => Segment_After (Clean, "exit"),
            when Node_Goto_Statement    => Segment_After (Clean, "goto"),
            when Node_Delay_Statement   => Segment_After (Clean, "delay"),
            when Node_Requeue_Statement => Segment_After (Clean, "requeue"),
            when Node_Abort_Statement   => Segment_After (Clean, "abort"),
            when others                 => "");
   begin
      if Clean = "" then
         return;
      end if;

      if Is_Alternative then
         Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Alternative, Clean);
      end if;

      case Kind is
         when Node_Return_Statement =>
            Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Action, Tail);
         when Node_Raise_Statement =>
            if Contains (L, " with ") then
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
                  Segment_Before (Tail, "with"));
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Message,
                  Segment_After (Tail, "with"));
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Tail);
            end if;
         when Node_Exit_Statement =>
            if Contains (L, " when ") then
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
                  Segment_Before (Tail, "when"));
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Condition,
                  Segment_After (Tail, "when"));
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Tail);
            end if;
         when Node_Goto_Statement =>
            Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Tail);
         when Node_Delay_Statement =>
            if Starts_With_Word (L, "delay until") then
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Mode, "until");
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Condition,
                  Segment_After (Clean, "delay until"));
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Mode, "relative");
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Condition, Tail);
            end if;
         when Node_Requeue_Statement =>
            if Contains (L, " with abort") then
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
                  Segment_Before (Tail, "with abort"));
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Mode, "with abort");
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Tail);
            end if;
         when Node_Abort_Statement =>
            Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Tail);
         when Node_Assignment_Statement =>
            Add_Detail_Node
              (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
               Segment_Before (Clean, ":="));
            Add_Detail_Node
              (Tree, Stmt, Depth + 1, Line, Node_Statement_Action,
               Segment_After (Clean, ":="));
         when Node_Entry_Call_Statement =>
            Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Mode, "entry call");
            if Contains (Clean, "(") then
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
                  Segment_Before (Clean, "("));
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Arguments,
                  Segment_After (Clean, "("));
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Clean);
            end if;
         when Node_Call_Statement | Node_Accept_Statement | Node_Pragma_Statement =>
            if Contains (Clean, "(") then
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
                  Segment_Before (Clean, "("));
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Arguments,
                  Segment_After (Clean, "("));
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Clean);
            end if;
         when others =>
            null;
      end case;
   end Attach_Statement_Details;

   procedure Attach_Syntax_Details
     (Tree   : in out Tree_Type;
      Id     : Node_Id;
      Kind   : Node_Kind;
      Code   : String;
      Line   : Positive;
      Depth  : Natural);

   procedure Add_Structured_Statement_Node
     (Tree           : in out Tree_Type;
      Parent         : Node_Id;
      Depth          : Natural;
      Line           : Positive;
      Text           : String;
      Is_Alternative : Boolean := False)
   is
      Clean : constant String := Strip_Terminator (Text);
      Kind  : constant Node_Kind := Statement_Node_Kind (Clean);
      Stmt  : Node_Id;
   begin
      if Clean = "" then
         return;
      end if;

      Stmt := Add_Node
        (Tree, Kind, (Line, 1, Line, Last_Column_For (Clean)), Parent, Depth, Clean);

      if Is_Alternative then
         Add_Detail_Node
           (Tree, Stmt, Depth + 1, Line, Node_Statement_Alternative, Clean);
      end if;

      Attach_Syntax_Details (Tree, Stmt, Kind, Clean, Line, Depth + 1);
   end Add_Structured_Statement_Node;

   procedure Add_Action_Sequence
     (Tree           : in out Tree_Type;
      Parent         : Node_Id;
      Depth          : Natural;
      Line           : Positive;
      Text           : String;
      Is_Alternative : Boolean := False)
   is
      Clean : constant String := Trim (Text);
      Seq   : Node_Id;
      Start : Natural;
      Semi  : Natural;

      procedure Add_Action_Segment (Raw_Segment : String) is
         Segment : constant String := Trim (Raw_Segment);
         L       : constant String := Lower (Segment);
      begin
         if Segment = "" or else Starts_With_Word (L, "end") then
            return;
         elsif Starts_With_Word (L, "when") and then Contains (L, "=>") then
            Add_Detail_Node
              (Tree, Seq, Depth + 1, Line, Node_Statement_Alternative,
               Segment_Before (Segment_After (Segment, "when"), "=>"));
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment_After (Segment, "=>"), True);
         elsif Starts_With_Word (L, "else") then
            Add_Detail_Node (Tree, Seq, Depth + 1, Line, Node_Statement_Alternative, "else");
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment_After (Segment, "else"), True);
         elsif Starts_With_Word (L, "elsif") then
            Add_Detail_Node
              (Tree, Seq, Depth + 1, Line, Node_Statement_Alternative,
               Segment_Before (Segment_After (Segment, "elsif"), "then"));
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment, True);
         elsif Starts_With_Word (L, "then") and then Contains (L, "then abort") then
            Add_Detail_Node (Tree, Seq, Depth + 1, Line, Node_Statement_Mode, "then abort");
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment_After (Segment, "then abort"), True);
         elsif Starts_With_Word (L, "or") then
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment, True);
         else
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment, Is_Alternative);
         end if;
      end Add_Action_Segment;
   begin
      if Clean = "" then
         return;
      end if;

      Seq := Add_Node
        (Tree, Node_Statement_Sequence,
         (Line, 1, Line, Last_Column_For (Clean)), Parent, Depth, Clean);

      Start := Clean'First;
      while Start <= Clean'Last loop
         Semi := 0;
         for I in Start .. Clean'Last loop
            if Clean (I) = ';' then
               Semi := I;
               exit;
            end if;
         end loop;

         if Semi = 0 then
            Add_Action_Segment (Clean (Start .. Clean'Last));
            exit;
         elsif Semi > Start then
            Add_Action_Segment (Clean (Start .. Semi));
            Start := Semi + 1;
         else
            Start := Start + 1;
         end if;
      end loop;
   end Add_Action_Sequence;


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

   procedure Attach_Syntax_Details
     (Tree   : in out Tree_Type;
      Id     : Node_Id;
      Kind   : Node_Kind;
      Code   : String;
      Line   : Positive;
      Depth  : Natural)
   is
      L : constant String := Lower (Code);
      Semi : Natural;
   begin
      Add_Header_Recovery_Details (Tree, Id, Depth, Line, Kind, Code);
      case Kind is
         when Node_Package_Declaration
            | Node_Package_Body
            | Node_Subprogram_Declaration
            | Node_Abstract_Subprogram_Declaration
            | Node_Null_Procedure_Declaration
            | Node_Expression_Function_Declaration
            | Node_Subprogram_Body
            | Node_Type_Declaration
            | Node_Subtype_Declaration
            | Node_Object_Declaration
            | Node_Constant_Declaration
            | Node_Deferred_Constant_Declaration
            | Node_Number_Declaration
            | Node_Component_Declaration
            | Node_Discriminant_Specification
            | Node_Parameter_Specification
            | Node_Formal_Object_Declaration
            | Node_Formal_Type_Declaration
            | Node_Formal_Subprogram_Declaration
            | Node_Exception_Declaration
            | Node_Generic_Declaration
            | Node_Rename_Declaration
            | Node_Separate_Body
            | Node_Task_Declaration
            | Node_Task_Type_Declaration
            | Node_Single_Task_Declaration
            | Node_Task_Body
            | Node_Protected_Declaration
            | Node_Protected_Type_Declaration
            | Node_Single_Protected_Declaration
            | Node_Protected_Body
            | Node_Entry_Declaration
            | Node_Entry_Body
            | Node_Entry_Body_Stub
            | Node_Private_Part
            | Node_Incomplete_Type_Declaration
            | Node_Private_Extension_Declaration
            | Node_Body_Stub
            | Node_Choice_Parameter_Specification
            | Node_Enumeration_Literal_Declaration =>
            Add_Declaration_Detail_Nodes (Tree, Id, Depth, Line, Code, Kind);
            if Kind = Node_Type_Declaration
              or else Kind = Node_Private_Extension_Declaration
            then
               Add_Discriminant_Nodes (Tree, Id, Depth, Line, Code);
               Add_Enumeration_Literal_Nodes (Tree, Id, Depth, Line, Code);
            end if;
            if Contains (L, " with ") then
               Add_Aspect_Specification_Nodes (Tree, Id, Depth, Line, Code);
            end if;
            if Kind = Node_Type_Declaration or else Kind = Node_Subtype_Declaration or else Kind = Node_Private_Extension_Declaration then
               Add_Expression_Nodes (Tree, Id, Depth, Line, Code);
            elsif Kind = Node_Object_Declaration
              or else Kind = Node_Constant_Declaration
              or else Kind = Node_Deferred_Constant_Declaration
              or else Kind = Node_Number_Declaration
            then
               Add_Expression_Nodes (Tree, Id, Depth, Line, Segment_Before (Code, ":"));
               if Contains (Code, ":=") then
                  Add_Expression_Nodes (Tree, Id, Depth, Line, Segment_After (Code, ":="));
               end if;
            end if;
         when Node_Instantiation =>
            Add_Generic_Actual_Part_Nodes (Tree, Id, Depth, Line, Code);
            if Contains (L, " with ") then
               Add_Aspect_Specification_Nodes (Tree, Id, Depth, Line, Code);
            end if;
         when Node_Formal_Package_Declaration =>
            Add_Declaration_Detail_Nodes (Tree, Id, Depth, Line, Code, Kind);
            --  Formal package declarations have the same association-list
            --  grammar as ordinary generic actual parts, but they are generic
            --  formal declarations rather than instantiations:
            --     with package P is new G (A => B, others => <>);
            --  Retain the actual-part nodes under the formal package symbol so
            --  language-model projection can expose named actual selectors,
            --  box defaults, and duplicate/ordering diagnostics without
            --  treating the generic package name itself as an expression.
            if Trim (Segment_Between_First_Parens (Code)) /= "<>" then
               Add_Generic_Actual_Part_Nodes (Tree, Id, Depth, Line, Code);
            end if;
            if Contains (L, " with ") then
               Add_Aspect_Specification_Nodes (Tree, Id, Depth, Line, Code);
            end if;
         when Node_Aspect_Specification =>
            Add_Association_List_Nodes
              (Tree, Id, Depth, Line, Strip_Leading_With (Code), Node_Aspect_Association);
         when Node_Generic_Actual_Part =>
            declare
               Actuals : constant String :=
                 (if Segment_Between_First_Parens (Code) /= "" then
                    Segment_Between_First_Parens (Code)
                  else
                    Code);
            begin
               Add_Association_List_Nodes
                 (Tree, Id, Depth, Line, Actuals, Node_Generic_Actual_Association);
            end;
         when Node_Representation_Clause =>
            Add_Representation_Clause_Detail_Nodes (Tree, Id, Depth, Line, Code);
         when Node_Representation_Component_Clause =>
            Add_Representation_Component_Clause_Detail_Nodes (Tree, Id, Depth, Line, Code);
         when Node_Representation_Mod_Clause =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Representation_Item,
               Segment_After (Code, "mod"));
         when Node_Variant_Part =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Selector,
               Segment_Before (Segment_After (Code, "case"), "is"));
         when Node_Variant =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Alternative,
               Segment_Before (Segment_After (Code, "when"), "=>"));
            declare
               Decls : constant String := Segment_After (Code, "=>");
               Start : Natural := Decls'First;
               Semi  : Natural;
            begin
               while Decls /= "" and then Start <= Decls'Last loop
                  Semi := 0;
                  for I in Start .. Decls'Last loop
                     if Decls (I) = ';' then
                        Semi := I;
                        exit;
                     end if;
                  end loop;
                  declare
                     Piece : constant String :=
                       Trim (if Semi = 0 then Decls (Start .. Decls'Last) else Decls (Start .. Semi));
                  begin
                     if Piece /= "" and then Contains (Piece, ":") then
                        declare
                           Component : constant Node_Id := Add_Node
                             (Tree, Node_Component_Declaration,
                              (Line, 1, Line, Last_Column_For (Piece)), Id, Depth + 1, Piece);
                        begin
                           Add_Declaration_Detail_Nodes
                             (Tree, Component, Depth + 2, Line, Piece, Node_Component_Declaration);
                        end;
                     elsif Piece /= "" then
                        Add_Action_Sequence (Tree, Id, Depth, Line, Piece, True);
                     end if;
                  end;
                  exit when Semi = 0;
                  Start := Semi + 1;
               end loop;
            end;
         when Node_If_Statement =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Condition,
               If_Condition_Text (Code, "if"));
            declare
               Tail : constant String := If_Action_Text (Code);
            begin
               if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                  Add_Action_Sequence
                    (Tree, Id, Depth, Line, Tail);
               end if;
            end;
         when Node_Elsif_Part =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Condition,
               If_Condition_Text (Code, "elsif"));
            declare
               Tail : constant String := If_Action_Text (Code);
            begin
               if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                  Add_Action_Sequence
                    (Tree, Id, Depth, Line, Tail);
               end if;
            end;
         when Node_Else_Part =>
            if First_Semicolon (Segment_After (Code, "else")) /= 0 then
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "else"), True);
            end if;
         when Node_Case_Statement =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Selector,
               Segment_Before (Segment_After (Code, "case"), "is"));
            if Contains (L, "=>") then
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "=>"), True);
            end if;
         when Node_When_Alternative =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Alternative,
               Segment_Before (Segment_After (Code, "when"), "=>"));
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Condition,
               Segment_Before (Segment_After (Code, "when"), "=>"));
            Add_Action_Sequence
              (Tree, Id, Depth, Line, Segment_After (Code, "=>"), True);
         when Node_Select_Alternative =>
            if Starts_With_Word (L, "then") and then Contains (L, "then abort") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Mode, "then abort");
               declare
                  Tail : constant String := Segment_After (Code, "then abort");
               begin
                  if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                     Add_Action_Sequence
                       (Tree, Id, Depth, Line, Tail, True);
                  end if;
               end;
            elsif Starts_With_Word (L, "else") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Alternative, "else");
               declare
                  Tail : constant String := Segment_After (Code, "else");
               begin
                  if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                     Add_Action_Sequence
                       (Tree, Id, Depth, Line, Tail, True);
                  end if;
               end;
            elsif Starts_With_Word (L, "terminate") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Mode, "terminate");
            else
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Alternative, "or");
               declare
                  Tail : constant String := Segment_After (Code, "or");
               begin
                  if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                     Add_Action_Sequence
                       (Tree, Id, Depth, Line, Tail, True);
                  end if;
               end;
            end if;
         when Node_Exception_Handler =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Alternative,
               Segment_Before (Segment_After (Code, "when"), "=>"));
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Condition,
               Segment_Before (Segment_After (Code, "when"), "=>"));
            Add_Action_Sequence
              (Tree, Id, Depth, Line, Segment_After (Code, "=>"), True);
         when Node_Exception_Section =>
            if Contains (L, " when ") and then Contains (L, "=>") then
               Add_Detail_Node
                 (Tree, Id, Depth, Line, Node_Statement_Alternative,
                  Segment_Before (Segment_After (Code, "when"), "=>"));
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "=>"), True);
            end if;
         when Node_Loop_Statement =>
            if Starts_With_Word (L, "while") then
               Add_Detail_Node
                 (Tree, Id, Depth, Line, Node_Statement_Condition,
                  Segment_Before (Segment_After (Code, "while"), "loop"));
            elsif Starts_With_Word (L, "for") then
               Add_Detail_Node
                 (Tree, Id, Depth, Line, Node_Statement_Selector,
                  Segment_Before (Segment_After (Code, "for"), "loop"));
            end if;
            declare
               Tail : constant String := Segment_After (Code, "loop");
            begin
               if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                  Add_Action_Sequence
                    (Tree, Id, Depth, Line, Tail);
               end if;
            end;
         when Node_Declare_Block =>
            if Contains (L, " begin ") then
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "begin"));
            end if;
         when Node_Begin_Block =>
            if First_Semicolon (Segment_After (Code, "begin")) /= 0 then
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "begin"));
            end if;
         when Node_Select_Statement =>
            if Contains (L, " then abort ") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Mode, "triggering");
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Segment_Before (Code, "then abort"), "select"));
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Mode, "then abort");
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "then abort"), True);
            elsif Contains (L, " terminate") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Mode, "terminate");
            elsif Starts_With_Word (L, "select") then
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "select"));
            end if;
         when Node_Accept_Statement =>
            Attach_Statement_Details (Tree, Id, Kind, Depth - 1, Line, Code);
            if Contains (L, " do ") then
               Add_Action_Sequence (Tree, Id, Depth, Line, Segment_After (Code, "do"));
            end if;
         when Node_Pragma_Statement =>
            Add_Detail_Node (Tree, Id, Depth, Line, Node_Pragma_Name, Segment_Before (Code, "("));
            Attach_Statement_Details (Tree, Id, Kind, Depth - 1, Line, Code);
            if Contains (Code, "(") then
               Add_Association_List_Nodes
                 (Tree, Id, Depth, Line, Segment_Between_First_Parens (Code), Node_Pragma_Argument);
            end if;
         when Node_Return_Statement
            | Node_Raise_Statement
            | Node_Exit_Statement
            | Node_Goto_Statement
            | Node_Requeue_Statement
            | Node_Delay_Statement
            | Node_Abort_Statement
            | Node_Terminate_Statement
            | Node_Assignment_Statement
            | Node_Entry_Call_Statement
            | Node_Call_Statement
            | Node_Null_Statement =>
            Attach_Statement_Details (Tree, Id, Kind, Depth - 1, Line, Code);
         when Node_Pragma =>
            Add_Detail_Node (Tree, Id, Depth, Line, Node_Pragma_Name, Segment_Before (Code, "("));
            Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Target, Segment_Before (Code, "("));
            if Contains (Code, "(") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Arguments, Segment_After (Code, "("));
               Add_Association_List_Nodes
                 (Tree, Id, Depth, Line, Segment_Between_First_Parens (Code), Node_Pragma_Argument);
            end if;
         when Node_Label =>
            Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Target, Code);
            Add_Name_Tokens (Tree, Id, Depth, Line, Code);
         when Node_End =>
            declare
               Target : constant String := End_Target_Text (Code);
            begin
               if Target /= "" then
                  Add_Detail_Node (Tree, Id, Depth, Line, Node_End_Target, Target);
               end if;
            end;
         when others =>
            null;
      end case;
   end Attach_Syntax_Details;

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

   function Has_Nodes (Tree : Tree_Type) return Boolean is
   begin
      return not Tree.Nodes.Is_Empty;
   end Has_Nodes;

   function Node_Count (Tree : Tree_Type) return Natural is
   begin
      return Natural (Tree.Nodes.Length);
   end Node_Count;

   function Root (Tree : Tree_Type) return Node_Id is
   begin
      return Tree.Root_Node;
   end Root;

   function Node (Tree : Tree_Type; Id : Node_Id) return Node_Info is
   begin
      if Id = No_Node or else Natural (Id) > Natural (Tree.Nodes.Length) then
         return (Id => No_Node, Kind => Node_Unknown, Source_Span => (1, 1, 1, 1),
                 Parent => No_Node, Depth => 0, Label => Null_Unbounded_String,
                 Fingerprint => 0);
      end if;
      return Tree.Nodes (Positive (Id));
   end Node;

   function Node_At (Tree : Tree_Type; Index : Positive) return Node_Info is
   begin
      if Index > Natural (Tree.Nodes.Length) then
         return (Id => No_Node, Kind => Node_Unknown, Source_Span => (1, 1, 1, 1),
                 Parent => No_Node, Depth => 0, Label => Null_Unbounded_String,
                 Fingerprint => 0);
      end if;
      return Tree.Nodes (Index);
   end Node_At;

   function Child_Count (Tree : Tree_Type; Parent : Node_Id) return Natural is
      Count : Natural := 0;
   begin
      for Info of Tree.Nodes loop
         if Info.Parent = Parent then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Child_Count;

   function Child_At
     (Tree   : Tree_Type;
      Parent : Node_Id;
      Index  : Positive) return Node_Id
   is
      Count : Natural := 0;
   begin
      for Info of Tree.Nodes loop
         if Info.Parent = Parent then
            Count := Count + 1;
            if Count = Index then
               return Info.Id;
            end if;
         end if;
      end loop;
      return No_Node;
   end Child_At;

   function Fingerprint (Tree : Tree_Type) return Natural is
   begin
      return Tree.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Syntax_Tree;
