with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Aspect_Inheritance_Rules;
with Editor.Ada_Body_Spec_Conformance;
with Editor.Ada_Call_Candidates;
with Editor.Ada_Call_Profile_Filters;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Call_Resolution;
with Editor.Ada_Child_Unit_Visibility;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Cross_Unit_Diagnostics;
with Editor.Ada_Cross_Unit_Lookup_Integration;
with Editor.Ada_Cross_Unit_Representation_Targets;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Cross_Unit_Visibility;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Expression_Diagnostics;
with Editor.Ada_Expression_Types;
with Editor.Ada_Expected_Call_Filters;
with Editor.Ada_Expected_Type_Contexts;
with Editor.Ada_Freezing_Interactions;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Dispatching_Call_Legality;
with Editor.Ada_Generic_Contract_Diagnostics;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Generic_Formal_Package_Nested_Conformance;
with Editor.Ada_Generic_Formal_Package_Substitutions;
with Editor.Ada_Generic_Formal_Type_Conformance;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Generic_Instantiated_Body_Analysis;
with Editor.Ada_Generic_Object_Default_Type_Conformance;
with Editor.Ada_Generic_Renaming_Visibility;
with Editor.Ada_Generic_View_Compatibility;
with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Limited_View_Rules;
with Editor.Ada_Nested_Body_Spec_Conformance;
with Editor.Ada_Operational_Attribute_Rules;
with Editor.Ada_Overload_Ambiguity_Diagnostics;
with Editor.Ada_Overload_Preference_Legality;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Overload_Ranking;
with Editor.Ada_Private_With_Rules;
with Editor.Ada_Private_View_Visibility;
with Editor.Ada_Project_Index;
with Editor.Ada_Record_Layout_Validation;
with Editor.Ada_Record_Layout_Exact_Validation;
with Editor.Ada_Record_Storage_Order_Rules;
with Editor.Ada_Representation_Diagnostics;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Selected_Name_Resolution;
with Editor.Ada_Selected_Representation_Targets;
with Editor.Ada_Separate_Body_Stub_Rules;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Stream_Attribute_Profile_Conformance;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tagged_Derived_Legality;
with Editor.Ada_Tasking_Protected_Legality;
with Editor.Ada_Type_Graph;
with Editor.Ada_Use_Type_Operators;
with Editor.Ada_Use_Visibility;
with Editor.Ada_View_Aware_Compatibility;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics.Accessibility;

package body Editor.Ada_Live_Semantic_Diagnostics is

   function Source_Unit_Name_For_Path
     (Index : Editor.Ada_Project_Index.Index_State;
      Path  : String) return String
   is
   begin
      for I in 1 .. Editor.Ada_Project_Index.Unit_Count (Index) loop
         declare
            Unit : constant Editor.Ada_Project_Index.Indexed_Unit :=
              Editor.Ada_Project_Index.Unit_At (Index, I);
         begin
            if To_String (Unit.Path) = Path then
               return To_String (Unit.Unit_Name);
            end if;
         end;
      end loop;

      return "";
   end Source_Unit_Name_For_Path;

   function Child_Context_For_Path
     (Index : Editor.Ada_Project_Index.Index_State;
      Path  : String)
      return Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context
   is
      use type Editor.Ada_Project_Index.Indexed_Unit_Role;
   begin
      for I in 1 .. Editor.Ada_Project_Index.Unit_Count (Index) loop
         declare
            Unit : constant Editor.Ada_Project_Index.Indexed_Unit :=
              Editor.Ada_Project_Index.Unit_At (Index, I);
         begin
            if To_String (Unit.Path) = Path then
               if Unit.Role = Editor.Ada_Project_Index.Unit_Package_Body then
                  return
                    Editor.Ada_Child_Unit_Visibility
                      .Child_Visibility_Context_Parent_Body;
               elsif Unit.Role =
                 Editor.Ada_Project_Index.Unit_Private_Package_Spec
               then
                  return
                    Editor.Ada_Child_Unit_Visibility
                      .Child_Visibility_Context_Parent_Private_Part;
               end if;
            end if;
         end;
      end loop;

      return
        Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_External_Client;
   end Child_Context_For_Path;

   function To_Service_Severity
     (Severity : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Severity)
      return Editor.Ada_Language_Service.Semantic_Diagnostic_Severity
   is
   begin
      case Severity is
         when Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Error =>
            return Editor.Ada_Language_Service.Semantic_Error;
         when Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Warning =>
            return Editor.Ada_Language_Service.Semantic_Warning;
         when Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Severity_Info =>
            return Editor.Ada_Language_Service.Semantic_Info;
      end case;
   end To_Service_Severity;

   function Source_Path_For_Unit
     (Index     : Editor.Ada_Project_Index.Index_State;
      Unit_Name : String) return String
   is
      Result : constant Editor.Ada_Project_Index.Unit_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve_Unit (Index, Unit_Name);
   begin
      if not Result.Matches.Is_Empty then
         return To_String
           (Result.Matches.Element (Result.Matches.First_Index).Path);
      elsif Editor.Ada_Project_Index.File_Count (Index) > 0 then
         return To_String (Editor.Ada_Project_Index.File_Key_At (Index, 1).Path);
      else
         return "";
      end if;
   end Source_Path_For_Unit;

   procedure Publish
     (Service              : in out Editor.Ada_Language_Service.Service_State;
      Path                 : String;
      Text                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis             : Editor.Ada_Language_Model.Analysis_Result)
   is
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Text);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);
      Project_Index : constant Editor.Ada_Project_Index.Index_State :=
        Editor.Ada_Language_Service.Project_Index (Service);
      Source_Unit_Name : constant String :=
        Source_Unit_Name_For_Path (Project_Index, Path);
      Project_Closure : constant
        Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model :=
        Editor.Ada_Cross_Unit_Closure.Build (Project_Index);
      Project_Cross_Unit_Visibility : constant
        Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model :=
        Editor.Ada_Cross_Unit_Visibility.Build
          (Project_Index, Project_Closure);
      Project_Child_Visibility : constant
        Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model :=
        Editor.Ada_Child_Unit_Visibility.Build (Project_Closure);
      Cross_Unit_Lookup : constant
        Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model :=
        Editor.Ada_Cross_Unit_Lookup_Integration.Build_With_Children
          (Project_Cross_Unit_Visibility,
           Project_Child_Visibility,
           Source_Unit_Name,
           Child_Context_For_Path (Project_Index, Path));
      Selected_Names : constant Editor.Ada_Selected_Name_Resolution.Selected_Name_Model :=
        Editor.Ada_Selected_Name_Resolution.Build_With_Cross_Unit
          (Tree, Regions, Visibility, Uses, Cross_Unit_Lookup);
      Candidates : constant Editor.Ada_Call_Candidates.Call_Candidate_Model :=
        Editor.Ada_Call_Candidates.Build
          (Tree, Regions, Visibility, Uses, Primitive_Uses);
      Profile_Shapes : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Profile_Filters : constant Editor.Ada_Call_Profile_Filters.Profile_Filter_Model :=
        Editor.Ada_Call_Profile_Filters.Build
          (Candidates, Profile_Shapes, Visibility);
      Calls : constant Editor.Ada_Call_Resolution.Call_Resolution_Model :=
        Editor.Ada_Call_Resolution.Build (Candidates, Profile_Filters);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generic_Base : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Static_And_Type_Graph
          (Tree, Regions, Visibility, Static, Types);
      Generic_Formal_Types : constant
        Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model :=
        Editor.Ada_Generic_Formal_Type_Conformance.Build
          (Tree, Generic_Base, Types);
      Generic_Nested : constant
        Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model :=
        Editor.Ada_Generic_Formal_Package_Nested_Conformance.Build
          (Tree, Generic_Base);
      Generic_Renamings : constant
        Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model :=
        Editor.Ada_Generic_Renaming_Visibility.Build
          (Tree, Regions, Visibility, Generic_Base);
      Generic_Object_Defaults : constant
        Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model :=
        Editor.Ada_Generic_Object_Default_Type_Conformance.Build
          (Tree, Generic_Base, Static, Types);
      Generic_Substitutions : constant
        Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Model :=
        Editor.Ada_Generic_Formal_Package_Substitutions.Build (Generic_Nested);
      Legality : constant
        Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build_With_Stream_Profiles
          (Tree, Regions, Visibility, Types, Static, Freezing, Profile_Shapes);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Exact_Layout : constant
        Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model :=
        Editor.Ada_Record_Layout_Exact_Validation.Build (Legality, Layout);
      Storage : constant
        Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant
        Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant
        Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Interactions : constant
        Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing, Types, Private_Views, Generic_Base);
      Empty_Cross_Unit_Visibility :
        Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Cross_Unit_Representation_Targets : constant
        Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Model :=
        Editor.Ada_Cross_Unit_Representation_Targets.Build
          (Path, Legality, Empty_Cross_Unit_Visibility);
      Selected_Representation_Targets : constant
        Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model :=
        Editor.Ada_Selected_Representation_Targets.Build
          (Cross_Unit_Representation_Targets, Selected_Names);
      Stream_Profiles : constant
        Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Model :=
        Editor.Ada_Stream_Attribute_Profile_Conformance.Build
          (Legality, Profile_Shapes);
      Expected : constant Editor.Ada_Expected_Type_Contexts.Expected_Context_Model :=
        Editor.Ada_Expected_Type_Contexts.Build
          (Tree, Regions, Visibility, Profile_Shapes, Calls);
      Expected_Filters : constant
        Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model :=
        Editor.Ada_Expected_Call_Filters.Build_With_Type_Graph
          (Expected, Calls, Profile_Filters, Profile_Shapes, Types);
      Expressions : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types
          .Build_With_Project_Cross_Unit_Selected_Names_Operator_Uses_And_Expected
          (Tree, Regions, Visibility, Types, Static, Calls, Selected_Names,
           Primitive_Uses, Expected, Project_Index);
      Views : constant
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model :=
        Editor.Ada_View_Aware_Compatibility.Build (Expressions);
      Assignment_Contexts : constant
        Editor.Ada_Assignment_Legality.Assignment_Context_Model :=
        Editor.Ada_Assignment_Legality.Build_Contexts_From_Expected_Types
          (Expected, Expressions);
      Assignment_Legality : constant
        Editor.Ada_Assignment_Legality.Assignment_Legality_Model :=
        Editor.Ada_Assignment_Legality.Build_With_Type_Graph
          (Assignment_Contexts, Expressions, Views, Types);
      Return_Contexts : constant
        Editor.Ada_Return_Legality.Return_Context_Model :=
        Editor.Ada_Return_Legality.Build_Contexts_From_Expected_Types
          (Expected, Assignment_Legality);
      Return_Legality : constant
        Editor.Ada_Return_Legality.Return_Legality_Model :=
        Editor.Ada_Return_Legality.Build
          (Return_Contexts, Assignment_Legality);
      Flow_Contexts : constant
        Editor.Ada_Control_Flow_Legality.Flow_Context_Model :=
        Editor.Ada_Control_Flow_Legality.Build_Contexts_From_Returns
          (Return_Legality);
      Flow_Legality : constant
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Model :=
        Editor.Ada_Control_Flow_Legality.Build
          (Flow_Contexts, Return_Legality);
      Tasking_Contexts : constant
        Editor.Ada_Tasking_Protected_Legality.Tasking_Context_Model :=
        Editor.Ada_Tasking_Protected_Legality.Build_Contexts_From_Syntax
          (Tree, Flow_Legality);
      Tasking_Legality : constant
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Model :=
        Editor.Ada_Tasking_Protected_Legality.Build
          (Tasking_Contexts, Flow_Legality);
      Conversion_Contexts : constant
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Context_Model :=
        Editor.Ada_Conversion_Access_Aggregate_Legality
          .Build_Contexts_From_Expression_Types (Expressions);
      Conversion_Legality : constant
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Build
          (Conversion_Contexts);
      Overload_Causes : constant
        Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model :=
        Editor.Ada_Overload_Ambiguity_Diagnostics.Build (Expressions);
      Overload_Rankings : constant
        Editor.Ada_Overload_Ranking.Overload_Ranking_Model :=
        Editor.Ada_Overload_Ranking.Build (Expressions, Overload_Causes);
      Generic_Views : constant
        Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model :=
        Editor.Ada_Generic_View_Compatibility.Build
          (Generic_Object_Defaults, Views);
      Generic_Bodies : constant
        Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.Build
          (Generic_Base, Generic_Views);
      Dispatching : constant
        Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model :=
        Editor.Ada_Dispatching_Call_Legality.Build (Expressions);
      Tagged_Contexts : constant
        Editor.Ada_Tagged_Derived_Legality.Tagged_Context_Model :=
        Editor.Ada_Tagged_Derived_Legality.Build_Contexts_From_Syntax
          (Tree, Dispatching);
      Tagged_Legality : constant
        Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Model :=
        Editor.Ada_Tagged_Derived_Legality.Build
          (Tagged_Contexts, Assignment_Legality, Return_Legality, Dispatching);
      Overload_Contexts : constant
        Editor.Ada_Overload_Resolution_Legality.Overload_Context_Model :=
        Editor.Ada_Overload_Resolution_Legality.Build_Contexts_From_Expected_Call_Filters
          (Expected_Filters);
      Instance_Contexts : constant
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Context_Model :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Build_Contexts_From_Models
          (Generic_Base,
           Generic_Bodies,
           Generic_Substitutions,
           Freezing,
           Legality);
      Instance_Legality : constant
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Model :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Build
          (Instance_Contexts,
           Generic_Bodies,
           Generic_Substitutions,
           Freezing,
           Legality,
           Assignment_Legality,
           Return_Legality,
           Conversion_Legality,
           Tagged_Legality);
      Empty_Cross_Unit_Closure :
        Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Cross_Unit_Semantic_Contexts : constant
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Context_Model :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Build_Local_Contexts_From_Legality
          (Path,
           Assignment_Legality,
           Return_Legality,
           Conversion_Legality,
           Flow_Legality,
           Tasking_Legality,
           Tagged_Legality,
           Instance_Legality);
      Cross_Unit_Semantic : constant
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Model :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Build
          (Cross_Unit_Semantic_Contexts,
           Empty_Cross_Unit_Closure,
           Cross_Unit_Lookup,
           Assignment_Legality,
           Return_Legality,
           Conversion_Legality,
           Flow_Legality,
           Tasking_Legality,
           Tagged_Legality,
           Instance_Legality);
      Accessibility_Contexts : constant
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Context_Model :=
        Editor.Ada_Accessibility_Lifetime_Legality.Build_Contexts_From_Semantic_Legality
          (Conversion_Legality);
      Accessibility_Legality : constant
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Model :=
        Editor.Ada_Accessibility_Lifetime_Legality.Build (Accessibility_Contexts);
      Wide_Diags : constant
        Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Model :=
        Editor.Ada_Wide_Semantic_Legality_Diagnostics.Accessibility.Build_With_Accessibility
          (Assignment_Legality,
           Return_Legality,
           Conversion_Legality,
           Flow_Legality,
           Tasking_Legality,
           Tagged_Legality,
           Instance_Legality,
           Cross_Unit_Semantic,
           Accessibility_Legality);
      Overload_Legality : constant
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Model :=
        Editor.Ada_Overload_Resolution_Legality.Build
          (Overload_Contexts, Overload_Rankings, Wide_Diags);
      Overload_Preference_Contexts : constant
        Editor.Ada_Overload_Preference_Legality.Preference_Context_Model :=
        Editor.Ada_Overload_Preference_Legality.Build_Contexts_From_Overload_Legality
          (Overload_Legality);
      Overload_Preference : constant
        Editor.Ada_Overload_Preference_Legality.Preference_Legality_Model :=
        Editor.Ada_Overload_Preference_Legality.Build
          (Overload_Legality, Overload_Preference_Contexts);
      Generic_Diags : constant
        Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model :=
        Editor.Ada_Generic_Contract_Diagnostics.Build_With_Formal_Package_Substitutions
          (Generic_Formal_Types,
           Generic_Nested,
           Generic_Renamings,
           Generic_Object_Defaults,
           Generic_Views,
           Generic_Bodies,
           Generic_Substitutions);
      Expression_Diags : constant
        Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model :=
        Editor.Ada_Expression_Diagnostics
          .Build_With_All_Semantic_Causes_Ranking_And_Overload_Legality
            (Expressions,
             Overload_Causes,
             Views,
             Dispatching,
             Overload_Rankings,
             Overload_Legality);
      Representation_Diags : constant
        Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model :=
        Editor.Ada_Representation_Diagnostics
          .Build_With_Selected_Targets_Exact_Layout_And_Stream_Profiles
            (Legality,
             Layout,
             Storage,
             Operational,
             Inheritance,
             Interactions,
             Selected_Representation_Targets,
             Exact_Layout,
             Stream_Profiles);
      Empty_Cross_Unit_Diags :
        Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Colours : constant
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model :=
        Editor.Ada_Semantic_Colour_Projection.Build
          (Expression_Diags,
           Generic_Diags,
           Empty_Cross_Unit_Diags,
           Representation_Diags);
      Produced : constant
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          (Path,
           Buffer_Token,
           Buffer_Revision,
           Lifecycle_Generation,
           0,
           Editor.Ada_Language_Model.Fingerprint (Analysis));
      Current : constant
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          (Path,
           Buffer_Token,
           Buffer_Revision,
           Lifecycle_Generation,
           0,
           Editor.Ada_Language_Model.Fingerprint (Analysis));
      Guarded : constant
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Current, Colours);
      Feed : constant
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Wide_Legality_And_Overload_Preference
          (Guarded, Wide_Diags, Overload_Preference);
   begin
      Editor.Ada_Language_Service.Put_Semantic_Diagnostic_Feed
        (Service, Path, Feed, "live-semantic");
   end Publish;

   procedure Publish_Cross_Unit
     (Service : in out Editor.Ada_Language_Service.Service_State;
      Index   : Editor.Ada_Project_Index.Index_State)
   is
      Closure : constant Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model :=
        Editor.Ada_Cross_Unit_Closure.Build (Index);
      Visibility : constant Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model :=
        Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Limited_View : constant Editor.Ada_Limited_View_Rules.Limited_View_Model :=
        Editor.Ada_Limited_View_Rules.Build (Visibility);
      Private_W : constant Editor.Ada_Private_With_Rules.Private_With_Model :=
        Editor.Ada_Private_With_Rules.Build (Visibility);
      Body_Spec : constant Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model :=
        Editor.Ada_Body_Spec_Conformance.Build (Index, Closure);
      Children : constant Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model :=
        Editor.Ada_Child_Unit_Visibility.Build (Closure);
      Separates : constant Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Model :=
        Editor.Ada_Separate_Body_Stub_Rules.Build (Index, Closure);
      Nested : constant
        Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Model :=
        Editor.Ada_Nested_Body_Spec_Conformance.Build (Index, Body_Spec);
      Diagnostics : constant
        Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model :=
        Editor.Ada_Cross_Unit_Diagnostics.Build_With_Nested
          (Visibility, Limited_View, Private_W, Body_Spec, Children, Separates, Nested);
   begin
      for I in 1 .. Editor.Ada_Project_Index.File_Count (Index) loop
         declare
            Key : constant Editor.Ada_Project_Index.Indexed_File_Key :=
              Editor.Ada_Project_Index.File_Key_At (Index, I);
         begin
            Editor.Ada_Language_Service.Clear_Semantic_Diagnostics_By_Source_Prefix
              (Service, To_String (Key.Path), "live-semantic-cross-unit:");
         end;
      end loop;

      for I in 1 .. Editor.Ada_Cross_Unit_Diagnostics.Diagnostic_Count (Diagnostics) loop
         declare
            Diagnostic : constant Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Info :=
              Editor.Ada_Cross_Unit_Diagnostics.Diagnostic_At (Diagnostics, I);
            Path : constant String :=
              Source_Path_For_Unit (Index, To_String (Diagnostic.Source_Unit_Name));
         begin
            if Path'Length > 0 then
               Editor.Ada_Language_Service.Put_Semantic_Diagnostic
                 (Service,
                  (Severity     => To_Service_Severity (Diagnostic.Severity),
                   Message      => Diagnostic.Message,
                   Path         => To_Unbounded_String (Path),
                   Has_Location => True,
                   Line         => Diagnostic.Start_Line,
                   Column       => Diagnostic.Start_Column,
                   Source       => To_Unbounded_String
                     ("live-semantic-cross-unit:" &
                      Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Kind'Image
                        (Diagnostic.Kind))));
            end if;
         end;
      end loop;
   end Publish_Cross_Unit;

end Editor.Ada_Live_Semantic_Diagnostics;
