package Editor.Ada_Token_Cursor.Expressions is

   function At_Iterator_Filter_Condition_Boundary
     (Position : Cursor) return Boolean;

   function At_Case_Statement_Selector_Reserved_Boundary
     (Position : Cursor) return Boolean;

   function At_Loop_Domain_Reserved_Boundary
     (Position : Cursor) return Boolean;

   function At_Iterated_Component_Expression_Boundary
     (Position : Cursor) return Boolean;

   function At_Aggregate_Component_Expression_Boundary
     (Position : Cursor) return Boolean;

   function At_Conditional_Expression_Dependent_Boundary
     (Position : Cursor) return Boolean;

   function At_Case_Expression_Selector_Boundary
     (Position : Cursor) return Boolean;

   function At_Quantified_Predicate_Boundary
     (Position : Cursor) return Boolean;

   function At_Declare_Expression_Body_Boundary
     (Position : Cursor) return Boolean;

   function Parenthesized_Constraint_Has_Arrow
     (Position : Cursor) return Boolean;

   function Has_Top_Level_Arrow_Before_Constraint_Association_End
     (Position : Cursor) return Boolean;

   function Parenthesized_Name_Suffix_Is_Slice
     (Position : Cursor) return Boolean;

end Editor.Ada_Token_Cursor.Expressions;
