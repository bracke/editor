with Editor.Ada_Declaration_Parser.Representation_Metadata;

package body Editor.Ada_Declaration_Parser.Representation_Application is

   use Editor.Ada_Language_Model;
   use Editor.Ada_Syntax_Tree;

   package Representation_Metadata
     renames Editor.Ada_Declaration_Parser.Representation_Metadata;

   function Is_Complete (Context : Application_Context) return Boolean is
   begin
      return Context.First_Child_Label /= null
        and then Context.Last_Child_Label /= null
        and then Context.To_Model_Range /= null
        and then Context.Find_Metadata_Target /= null
        and then Context.Normalize_Name /= null
        and then Context.Ancestor_Symbol /= null
        and then Context.Parent_Representation_Target /= null
        and then Context.Find_Enumeration_Literal /= null
        and then Context.Enumeration_Literal_At /= null
        and then Context.Find_Component /= null
        and then Context.Symbol_Name /= null
        and then Context.Parse_Static_Natural /= null
        and then Context.Register_Static_Attribute /= null;
   end Is_Complete;

   function Create_Context
     (First_Child_Label : Child_Label_Function;
      Last_Child_Label  : Child_Label_Function;
      To_Model_Range    : Source_Range_Function;
      Find_Metadata_Target : Symbol_Lookup_Function;
      Normalize_Name       : Name_Normalizer_Function;
      Ancestor_Symbol      : Scoped_Symbol_Function;
      Parent_Representation_Target : Scoped_Symbol_Function;
      Find_Enumeration_Literal : Enumeration_Literal_Function;
      Enumeration_Literal_At   : Enumeration_Position_Function;
      Find_Component           : Component_Lookup_Function;
      Symbol_Name              : Symbol_Name_Function;
      Parse_Static_Natural     : Static_Natural_Parser;
      Register_Static_Attribute : Static_Attribute_Registration)
      return Application_Context
   is
   begin
      return
        (First_Child_Label => First_Child_Label,
         Last_Child_Label  => Last_Child_Label,
         To_Model_Range    => To_Model_Range,
         Find_Metadata_Target => Find_Metadata_Target,
         Normalize_Name => Normalize_Name,
         Ancestor_Symbol => Ancestor_Symbol,
         Parent_Representation_Target => Parent_Representation_Target,
         Find_Enumeration_Literal => Find_Enumeration_Literal,
         Enumeration_Literal_At => Enumeration_Literal_At,
         Find_Component => Find_Component,
         Symbol_Name => Symbol_Name,
         Parse_Static_Natural => Parse_Static_Natural,
         Register_Static_Attribute => Register_Static_Attribute);
   end Create_Context;

   function Has_Dot (Text : String) return Boolean is
   begin
      for Ch of Text loop
         if Ch = '.' then
            return True;
         end if;
      end loop;
      return False;
   end Has_Dot;

   procedure Apply_Enumeration_Representation_Associations
     (Context  : Application_Context;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Clause_Node : Node_Id;
      Target      : Symbol_Id)
   is
      Positional_Index : Positive := 1;
   begin
      if Target = No_Symbol then
         return;
      end if;

      for C in 1 .. Child_Count (Tree, Clause_Node) loop
         declare
            Child_Id : constant Node_Id := Child_At (Tree, Clause_Node, C);
            Child    : constant Node_Info := Editor.Ada_Syntax_Tree.Node
              (Tree, Child_Id);
         begin
            if Child.Kind = Node_Named_Association then
               declare
                  Selector_Text : constant String :=
                    Context.First_Child_Label.all
                      (Child_Id, Node_Statement_Target);
                  Action_Text : constant String :=
                    Context.First_Child_Label.all
                      (Child_Id, Node_Statement_Action);
                  Is_Named : constant Boolean := Action_Text /= "";
                  Lit : Symbol_Id := No_Symbol;
                  Lit_Name_Buffer : Unbounded_String := Null_Unbounded_String;
                  Value_Text_Buffer : Unbounded_String := Null_Unbounded_String;
                  Has_Value : Boolean := False;
                  Value : Natural := 0;
               begin
                  if Is_Named then
                     Lit := Context.Find_Enumeration_Literal.all
                       (Target, Selector_Text);
                     Lit_Name_Buffer := To_Unbounded_String (Selector_Text);
                     Value_Text_Buffer := To_Unbounded_String (Action_Text);
                  else
                     Lit := Context.Enumeration_Literal_At.all
                       (Target, Positional_Index);
                     if Lit = No_Symbol then
                        Lit_Name_Buffer :=
                          To_Unbounded_String
                            ("<positional" &
                             Positive'Image (Positional_Index) & ">");
                     else
                        Lit_Name_Buffer :=
                          To_Unbounded_String (Context.Symbol_Name.all (Lit));
                     end if;
                     Value_Text_Buffer := To_Unbounded_String (Selector_Text);
                     Positional_Index := Positional_Index + 1;
                  end if;

                  if To_String (Value_Text_Buffer) /= "" then
                     Context.Parse_Static_Natural.all
                       (To_String (Value_Text_Buffer), Has_Value, Value);
                     Add_Enumeration_Representation_Literal
                       (Analysis,
                        Target_Symbol => Target,
                        Literal_Symbol => Lit,
                        Literal_Name => To_String (Lit_Name_Buffer),
                        Value_Text => To_String (Value_Text_Buffer),
                        Has_Static_Value => Has_Value,
                        Static_Value => Value,
                        Source_Span =>
                          Context.To_Model_Range.all (Child.Source_Span));
                  end if;
               end;
            end if;
         end;
      end loop;
   end Apply_Enumeration_Representation_Associations;

   procedure Apply_General_Representation_Clause
     (Context  : Application_Context;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Node     : Node_Info)
   is
      Raw_Target : constant String :=
        Context.First_Child_Label.all (Node.Id, Node_Representation_Target);
      Item_Text  : constant String :=
        Context.First_Child_Label.all (Node.Id, Node_Representation_Item);
      Attr       : constant String :=
        Representation_Metadata.Attribute_Name (Raw_Target);
      Base_Name  : constant String :=
        Representation_Metadata.Attribute_Base_Name (Raw_Target);
      Kind       : constant Representation_Clause_Kind :=
        Representation_Metadata.Attribute_Representation_Kind_For
          (Raw_Target, Item_Text, To_String (Node.Label));

      function Scoped_Target return Symbol_Id is
         Owner : constant Symbol_Id := Context.Ancestor_Symbol.all (Node.Id);
         Wanted : constant String := Context.Normalize_Name.all (Base_Name);
      begin
         if Has_Dot (Base_Name) or else Owner = No_Symbol then
            return Context.Find_Metadata_Target.all (Base_Name);
         end if;

         for I in reverse 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if S.Parent_Symbol = Owner
                 and then To_String (S.Normalized_Name) = Wanted
                 and then S.Source_Span.Start_Line <= Node.Source_Span.Start_Line
               then
                  return S.Id;
               end if;
            end;
         end loop;

         return Context.Find_Metadata_Target.all (Base_Name);
      end Scoped_Target;

      Target     : constant Symbol_Id := Scoped_Target;
      Has_Value  : Boolean := False;
      Value      : Natural := 0;
   begin
      if Raw_Target = "" then
         return;
      end if;

      Context.Parse_Static_Natural.all (Item_Text, Has_Value, Value);
      Add_Representation_Clause
        (Analysis,
         Target_Symbol => Target,
         Target_Name => Base_Name,
         Kind => Kind,
         Attribute_Name => Attr,
         Item_Text => Item_Text,
         Source_Form =>
           Representation_Metadata.Representation_Source_Form_For (Kind),
         Has_Static_Value => Has_Value,
         Static_Value => Value,
         Source_Span => Context.To_Model_Range.all (Node.Source_Span));

      if Has_Value then
         Context.Register_Static_Attribute.all (Base_Name, Attr, Value);
      end if;

      if Kind = Representation_Enumeration_Clause then
         Apply_Enumeration_Representation_Associations
           (Context, Tree, Analysis, Node.Id, Target);
      end if;
   end Apply_General_Representation_Clause;

   procedure Apply_Record_Representation_Component
     (Context  : Application_Context;
      Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Node     : Node_Info)
   is
      Target : constant Symbol_Id :=
        Context.Parent_Representation_Target.all (Node.Id);
      Component_Name : constant String :=
        Context.First_Child_Label.all (Node.Id, Node_Representation_Target);
      Item_Text : constant String :=
        Context.First_Child_Label.all (Node.Id, Node_Representation_Item);
      Range_Text : constant String :=
        Context.Last_Child_Label.all (Node.Id, Node_Range_Expression);
      Storage_Text : constant String :=
        Representation_Metadata.Record_Component_Storage_Unit_Text
          (Item_Text);
      First_Text : Unbounded_String := Null_Unbounded_String;
      Last_Text  : Unbounded_String := Null_Unbounded_String;
      Has_Storage : Boolean := False;
      Storage_Value : Natural := 0;
      Has_First : Boolean := False;
      First_Value : Natural := 0;
      Has_Last : Boolean := False;
      Last_Value : Natural := 0;
      Component : Symbol_Id;
   begin
      if Target = No_Symbol or else Component_Name = "" then
         return;
      end if;

      Representation_Metadata.Parse_Bit_Range
        (Range_Text, First_Text, Last_Text);
      Context.Parse_Static_Natural.all
        (Storage_Text, Has_Storage, Storage_Value);
      Context.Parse_Static_Natural.all
        (To_String (First_Text), Has_First, First_Value);
      Context.Parse_Static_Natural.all
        (To_String (Last_Text), Has_Last, Last_Value);
      Component := Context.Find_Component.all (Target, Component_Name);

      Add_Record_Representation_Component
        (Analysis,
         Target_Symbol => Target,
         Component_Symbol => Component,
         Component_Name => Component_Name,
         Storage_Unit_Text => Storage_Text,
         First_Bit_Text => To_String (First_Text),
         Last_Bit_Text => To_String (Last_Text),
         Source_Form => Representation_Source_Record_Component_Clause,
         Has_Static_Storage_Unit => Has_Storage,
         Static_Storage_Unit => Storage_Value,
         Has_Static_First_Bit => Has_First,
         Static_First_Bit => First_Value,
         Has_Static_Last_Bit => Has_Last,
         Static_Last_Bit => Last_Value,
         Source_Span => Context.To_Model_Range.all (Node.Source_Span));
   end Apply_Record_Representation_Component;

   procedure Apply_Record_Representation_Mod_Clause
     (Context  : Application_Context;
      Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Node     : Node_Info)
   is
      Target : constant Symbol_Id :=
        Context.Parent_Representation_Target.all (Node.Id);
      Item_Text : constant String :=
        Context.First_Child_Label.all (Node.Id, Node_Representation_Item);
      Has_Value : Boolean := False;
      Value     : Natural := 0;
      Target_Name : Unbounded_String := Null_Unbounded_String;
   begin
      if Target = No_Symbol then
         return;
      end if;

      declare
         Target_Info : constant Symbol_Info :=
           Symbol_At (Analysis, Positive (Target));
      begin
         Target_Name := Target_Info.Name;
      end;

      Context.Parse_Static_Natural.all (Item_Text, Has_Value, Value);
      Add_Representation_Clause
        (Analysis,
         Target_Symbol => Target,
         Target_Name => To_String (Target_Name),
         Kind => Representation_Record_Mod_Clause,
         Attribute_Name => "mod",
         Item_Text => Item_Text,
         Source_Form => Representation_Source_Record_Clause,
         Has_Static_Value => Has_Value,
         Static_Value => Value,
         Source_Span => Context.To_Model_Range.all (Node.Source_Span));
   end Apply_Record_Representation_Mod_Clause;

end Editor.Ada_Declaration_Parser.Representation_Application;
