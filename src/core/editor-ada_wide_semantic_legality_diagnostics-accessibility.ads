with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Tagged_Derived_Legality;
with Editor.Ada_Tasking_Protected_Legality;

package Editor.Ada_Wide_Semantic_Legality_Diagnostics.Accessibility is

   function Build_With_Accessibility
     (Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model;
      Returns     : Editor.Ada_Return_Legality.Return_Legality_Model;
      Expressions : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model;
      Flow        : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model;
      Tasking     : Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Model;
      Tagged_Model : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Model;
      Instances   : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Model;
      Cross_Unit  : Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Model;
      Accessibility : Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Model)
      return Wide_Semantic_Diagnostic_Model;

end Editor.Ada_Wide_Semantic_Legality_Diagnostics.Accessibility;
