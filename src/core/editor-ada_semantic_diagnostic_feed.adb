with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
with Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration;
with Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
with Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
with Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration;
with Editor.Syntax;

package body Editor.Ada_Semantic_Diagnostic_Feed is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Source;
   use type Editor.Syntax.Token_Kind;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 43) mod 1_000_000_007;
   end Mix;

   function Severity_Of
     (Severity : Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Severity_Of
     (Severity : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Severity_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Source_Of
     (Family : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Family)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Family is
         when Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Generic_Instance =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract;
         when Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Cross_Unit =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Assignment
            | Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Return
            | Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Conversion_Access_Aggregate
            | Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Control_Flow
            | Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Tasking_Protected
            | Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Tagged_Derived
            | Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Unknown =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      end case;
   end Source_Of;



   function Severity_Of
     (Status : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Status)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Status is
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_Local
            | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_Cross_Unit
            | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_With_Use_Closure =>
            return Semantic_Diagnostic_Feed_Info;
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Limited_View_Barrier
            | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Private_View_Barrier
            | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Stale_Dependency
            | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Rejected_Stale_Input
            | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Indeterminate
            | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Not_Checked =>
            return Semantic_Diagnostic_Feed_Warning;
         when others =>
            return Semantic_Diagnostic_Feed_Error;
      end case;
   end Severity_Of;

   function Source_Of
     (Closure : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Info)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Closure.Blocker is
         when Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Representation =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation;
         when Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Dependency =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Wide_Legality
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Overload
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Staticness
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Accessibility
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Contract
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Elaboration
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Completion
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Renaming
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Exception_Finalization
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Definite_Initialization
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Dataflow
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Refined_Global_Depends
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_AST_Coverage
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Coverage_Gate
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Multiple
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Indeterminate
            | Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_None =>
            case Closure.Status is
               when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Missing_Dependency
                  | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Ambiguous_Dependency
                  | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Dependency_Overflow
                  | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Stale_Dependency
                  | Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Rejected_Stale_Input =>
                  return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
               when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Representation_Blocker =>
                  return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation;
               when others =>
                  return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
            end case;
      end case;
   end Source_Of;

   function Integrated_Closure_Is_Diagnostic
     (Status : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Status)
      return Boolean is
   begin
      return not (Status in
        Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_Local |
        Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_Cross_Unit |
        Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_With_Use_Closure);
   end Integrated_Closure_Is_Diagnostic;

   function Severity_Of
     (Severity : Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Severity_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Source_Of
     (Family : Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Source_Family)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Family is
         when Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Cross_Unit =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Generic_Replay =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract;
         when Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Representation_Freezing =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation;
         when Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Overload_Type
            | Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Flow_Contract
            | Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Tasking_Protected
            | Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Elaboration
            | Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Accessibility_Lifetime
            | Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Discriminant_Variant
            | Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Multiple
            | Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Unknown =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      end case;
   end Source_Of;


   function Severity_Of
     (Severity : Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Severity_Of
     (Severity : Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;


   function Severity_Of
     (Severity : Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Source_Of
     (Family : Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Family)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Family is
         when Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Cross_Unit =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Generic_Replay =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract;
         when Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Representation_Freezing =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation;
         when Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Overload_Type
            | Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Flow_Contract
            | Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Tasking_Protected
            | Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Elaboration
            | Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Accessibility_Lifetime
            | Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Discriminant_Variant
            | Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_AST_Coverage
            | Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_View_Barrier
            | Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Stale_Input
            | Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Multiple
            | Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Unknown =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      end case;
   end Source_Of;

   function Source_Of
     (Family : Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Family)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Family is
         when Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Cross_Unit =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Generic_Replay =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract;
         when Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Representation_Freezing =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation;
         when Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Overload_Type
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Flow_Contract
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Tasking_Protected
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Elaboration
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Accessibility_Lifetime
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Discriminant_Variant
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_AST_Coverage
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_View_Barrier
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Stale_Input
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Preserved_Error
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Multiple
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Indeterminate
            | Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Unknown =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      end case;
   end Source_Of;


   function Source_Of
     (Family : Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Family)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Family is
         when Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract;
         when Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Representation_Generic_Shared_State |
              Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Volatile_Atomic_Representation =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation;
         when Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Stabilized_Shared_State_Closure =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when others =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      end case;
   end Source_Of;



   function Severity_Of
     (Severity : Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Source_Of
     (Family : Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Family)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Family is
         when Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Cross_Unit_RM_Completion =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Representation_RM_Completion |
              Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Volatile_Atomic_Effect =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation;
         when Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Generic_Substitution =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract;
         when others =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      end case;
   end Source_Of;


   function Severity_Of
     (Severity : Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Source_Of
     (Family : Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Family)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Family is
         when Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Cross_Unit |
              Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Stabilized_Closure =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Representation |
              Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Volatile_Atomic =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation;
         when Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Generic_Substitution |
              Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Predicate_RM =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract;
         when others =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      end case;
   end Source_Of;



   function Severity_Of
     (Severity : Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Source_Of
     (Family : Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Family)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Family is
         when Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Cross_Unit =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Representation |
              Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Volatile_Atomic =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation;
         when Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Generic_Substitution |
              Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Predicate_Invariant =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract;
         when others =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      end case;
   end Source_Of;



   function Severity_Of
     (Severity : Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Diagnostic_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Diagnostic_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Diagnostic_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Diagnostic_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Source_Of
     (Family : Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Diagnostic_Family)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Family is
         when Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Diagnostic_Stabilized_Closure =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Diagnostic_Remaining_Edge =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
         when others =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      end case;
   end Source_Of;



   function Severity_Of
     (Severity : Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Severity)
      return Semantic_Diagnostic_Feed_Severity is
   begin
      case Severity is
         when Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Error =>
            return Semantic_Diagnostic_Feed_Error;
         when Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Warning =>
            return Semantic_Diagnostic_Feed_Warning;
         when Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Info =>
            return Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Source_Of
     (Family : Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family)
      return Semantic_Diagnostic_Feed_Source is
   begin
      case Family is
         when Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Stabilized_Closure =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit;
         when Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Remaining_Edge =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
         when others =>
            return Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      end case;
   end Source_Of;

   function Entry_Fingerprint
     (Feed_Item : Semantic_Diagnostic_Feed_Entry) return Natural
   is
      H : Natural := Natural (Feed_Item.Id);
      S : constant String := To_String (Feed_Item.Message);
   begin
      H := Mix (H, Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Source'Pos (Feed_Item.Source) + 1);
      H := Mix (H, Semantic_Diagnostic_Feed_Severity'Pos (Feed_Item.Severity) + 1);
      H := Mix (H, Editor.Syntax.Token_Kind'Pos (Feed_Item.Token) + 1);
      H := Mix (H, Natural (Feed_Item.Node));
      H := Mix (H, Feed_Item.Start_Line);
      H := Mix (H, Feed_Item.Start_Column);
      H := Mix (H, Feed_Item.End_Line);
      H := Mix (H, Feed_Item.End_Column);
      H := Mix (H, Feed_Item.Source_Fingerprint);
      for C of S loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Entry_Fingerprint;

   procedure Clear (Model : in out Semantic_Diagnostic_Feed_Model) is
   begin
      Model.Entries.Clear;
      Model.Feed_Status := Semantic_Diagnostic_Feed_Current;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Rejected_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model;
   begin
      if Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Rejected (Guarded) then
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total :=
           Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Rejected_Entry_Count (Guarded);
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Fingerprint (Guarded),
                Model.Rejected_Total + 1);
         return Model;
      end if;

      Model.Result_Fingerprint :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Fingerprint (Guarded);

      for Index in 1 .. Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Entry_Count (Guarded) loop
         declare
            Source_Entry : constant Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry :=
              Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Entry_At (Guarded, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Index);
            Feed_Item.Source := Source_Entry.Source;
            Feed_Item.Severity := Severity_Of (Source_Entry.Severity);
            Feed_Item.Token := Source_Entry.Token;
            Feed_Item.Node := Source_Entry.Node;
            Feed_Item.Message := Source_Entry.Message;
            Feed_Item.Start_Line := Source_Entry.Start_Line;
            Feed_Item.Start_Column := Source_Entry.Start_Column;
            Feed_Item.End_Line := Source_Entry.End_Line;
            Feed_Item.End_Column := Source_Entry.End_Column;
            Feed_Item.Source_Fingerprint := Source_Entry.Fingerprint;
            Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

            Model.Entries.Append (Feed_Item);
            case Feed_Item.Severity is
               when Semantic_Diagnostic_Feed_Error =>
                  Model.Error_Total := Model.Error_Total + 1;
               when Semantic_Diagnostic_Feed_Warning =>
                  Model.Warning_Total := Model.Warning_Total + 1;
               when Semantic_Diagnostic_Feed_Info =>
                  Model.Info_Total := Model.Info_Total + 1;
            end case;
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
         end;
      end loop;

      return Model;
   end Build;

   function Build_With_Wide_Legality
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Wide    : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Model;
      Wide_Input_Current : Boolean := True;
      Wide_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Wide_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Wide_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Wide_Semantic_Legality_Diagnostics.Fingerprint (Wide),
                Wide_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total :=
           Model.Rejected_Total + Wide_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_Wide_Semantic_Legality_Diagnostics.Fingerprint (Wide));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_Wide_Semantic_Legality_Diagnostics.Diagnostic_Count (Wide) loop
         declare
            Wide_Entry : constant Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Info :=
              Editor.Ada_Wide_Semantic_Legality_Diagnostics.Diagnostic_At (Wide, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
            Feed_Item.Source := Source_Of (Wide_Entry.Family);
            Feed_Item.Severity := Severity_Of (Wide_Entry.Severity);
            Feed_Item.Token := Editor.Syntax.Identifier;
            Feed_Item.Node := Wide_Entry.Node;
            Feed_Item.Message := Wide_Entry.Message;
            Feed_Item.Start_Line := Wide_Entry.Start_Line;
            Feed_Item.Start_Column := Wide_Entry.Start_Column;
            Feed_Item.End_Line := Wide_Entry.End_Line;
            Feed_Item.End_Column := Wide_Entry.End_Column;
            Feed_Item.Source_Fingerprint := Wide_Entry.Fingerprint;
            Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

            Model.Entries.Append (Feed_Item);
            case Feed_Item.Severity is
               when Semantic_Diagnostic_Feed_Error =>
                  Model.Error_Total := Model.Error_Total + 1;
               when Semantic_Diagnostic_Feed_Warning =>
                  Model.Warning_Total := Model.Warning_Total + 1;
               when Semantic_Diagnostic_Feed_Info =>
                  Model.Info_Total := Model.Info_Total + 1;
            end case;
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Wide_Semantic_Legality_Diagnostics.Fingerprint (Wide));
      return Model;
   end Build_With_Wide_Legality;


   function Build_With_Integrated_Closure
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Closure : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Model;
      Closure_Input_Current : Boolean := True;
      Closure_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Closure_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Closure_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Integrated_Semantic_Closure.Fingerprint (Closure),
                Closure_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total :=
           Model.Rejected_Total + Closure_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_Integrated_Semantic_Closure.Fingerprint (Closure));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_Integrated_Semantic_Closure.Closure_Count (Closure) loop
         declare
            Closure_Row : constant Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Info :=
              Editor.Ada_Integrated_Semantic_Closure.Closure_At (Closure, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            if Integrated_Closure_Is_Diagnostic (Closure_Row.Status) then
               Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
               Feed_Item.Source := Source_Of (Closure_Row);
               Feed_Item.Severity := Severity_Of (Closure_Row.Status);
               Feed_Item.Token := Editor.Syntax.Identifier;
               Feed_Item.Node := Closure_Row.Node;
               Feed_Item.Message := Closure_Row.Message;
               Feed_Item.Start_Line := Closure_Row.Start_Line;
               Feed_Item.Start_Column := Closure_Row.Start_Column;
               Feed_Item.End_Line := Closure_Row.End_Line;
               Feed_Item.End_Column := Closure_Row.End_Column;
               Feed_Item.Source_Fingerprint := Closure_Row.Fingerprint;
               Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

               Model.Entries.Append (Feed_Item);
               case Feed_Item.Severity is
                  when Semantic_Diagnostic_Feed_Error =>
                     Model.Error_Total := Model.Error_Total + 1;
                  when Semantic_Diagnostic_Feed_Warning =>
                     Model.Warning_Total := Model.Warning_Total + 1;
                  when Semantic_Diagnostic_Feed_Info =>
                     Model.Info_Total := Model.Info_Total + 1;
               end case;
               Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Integrated_Semantic_Closure.Fingerprint (Closure));
      return Model;
   end Build_With_Integrated_Closure;



   function Build_With_Final_Semantic_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Final_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Final_Semantic_Diagnostic_Integration.Fingerprint (Final),
                Final_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total :=
           Model.Rejected_Total + Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_Final_Semantic_Diagnostic_Integration.Fingerprint (Final));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_Final_Semantic_Diagnostic_Integration.Row_Count (Final) loop
         declare
            Final_Row : constant Editor.Ada_Final_Semantic_Diagnostic_Integration.Final_Diagnostic_Info :=
              Editor.Ada_Final_Semantic_Diagnostic_Integration.Row_At (Final, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            if Editor.Ada_Final_Semantic_Diagnostic_Integration.Is_Emitted (Final_Row.Status) then
               Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
               Feed_Item.Source := Source_Of (Final_Row.Family);
               Feed_Item.Severity := Severity_Of (Final_Row.Severity);
               Feed_Item.Token := Editor.Syntax.Identifier;
               Feed_Item.Node := Final_Row.Node;
               Feed_Item.Message := Final_Row.Message;
               Feed_Item.Start_Line := Final_Row.Start_Line;
               Feed_Item.Start_Column := Final_Row.Start_Column;
               Feed_Item.End_Line := Final_Row.End_Line;
               Feed_Item.End_Column := Final_Row.End_Column;
               Feed_Item.Source_Fingerprint := Final_Row.Fingerprint;
               Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

               Model.Entries.Append (Feed_Item);
               case Feed_Item.Severity is
                  when Semantic_Diagnostic_Feed_Error =>
                     Model.Error_Total := Model.Error_Total + 1;
                  when Semantic_Diagnostic_Feed_Warning =>
                     Model.Warning_Total := Model.Warning_Total + 1;
                  when Semantic_Diagnostic_Feed_Info =>
                     Model.Info_Total := Model.Info_Total + 1;
               end case;
               Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Final_Semantic_Diagnostic_Integration.Fingerprint (Final));
      return Model;
   end Build_With_Final_Semantic_Diagnostics;



   function Build_With_Final_Remediation_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Final_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Fingerprint (Final),
                Final_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total := Model.Rejected_Total + Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Fingerprint (Final));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Row_Count (Final) loop
         declare
            Final_Row : constant Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Final_Remediation_Diagnostic_Row :=
              Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Row_At (Final, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            if Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Is_Emitted (Final_Row.Status) then
               Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
               Feed_Item.Source := Source_Of (Final_Row.Family);
               Feed_Item.Severity := Severity_Of (Final_Row.Severity);
               Feed_Item.Token := Editor.Syntax.Identifier;
               Feed_Item.Node := Final_Row.Node;
               Feed_Item.Message := Final_Row.Message;
               Feed_Item.Start_Line := Final_Row.Start_Line;
               Feed_Item.Start_Column := Final_Row.Start_Column;
               Feed_Item.End_Line := Final_Row.End_Line;
               Feed_Item.End_Column := Final_Row.End_Column;
               Feed_Item.Source_Fingerprint := Final_Row.Fingerprint;
               Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

               Model.Entries.Append (Feed_Item);
               case Feed_Item.Severity is
                  when Semantic_Diagnostic_Feed_Error =>
                     Model.Error_Total := Model.Error_Total + 1;
                  when Semantic_Diagnostic_Feed_Warning =>
                     Model.Warning_Total := Model.Warning_Total + 1;
                  when Semantic_Diagnostic_Feed_Info =>
                     Model.Info_Total := Model.Info_Total + 1;
               end case;
               Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration.Fingerprint (Final));
      return Model;
   end Build_With_Final_Remediation_Diagnostics;

   function Build_With_Final_Stabilized_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Final_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Fingerprint (Final),
                Final_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total := Model.Rejected_Total + Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Fingerprint (Final));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Row_Count (Final) loop
         declare
            Final_Row : constant Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Final_Stabilized_Diagnostic_Row :=
              Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Row_At (Final, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            if Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Is_Emitted (Final_Row.Status) then
               Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
               Feed_Item.Source := Source_Of (Final_Row.Family);
               Feed_Item.Severity := Severity_Of (Final_Row.Severity);
               Feed_Item.Token := Editor.Syntax.Identifier;
               Feed_Item.Node := Final_Row.Node;
               Feed_Item.Message := Final_Row.Message;
               Feed_Item.Start_Line := Final_Row.Start_Line;
               Feed_Item.Start_Column := Final_Row.Start_Column;
               Feed_Item.End_Line := Final_Row.End_Line;
               Feed_Item.End_Column := Final_Row.End_Column;
               Feed_Item.Source_Fingerprint := Final_Row.Diagnostic_Fingerprint;
               Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

               Model.Entries.Append (Feed_Item);
               case Feed_Item.Severity is
                  when Semantic_Diagnostic_Feed_Error =>
                     Model.Error_Total := Model.Error_Total + 1;
                  when Semantic_Diagnostic_Feed_Warning =>
                     Model.Warning_Total := Model.Warning_Total + 1;
                  when Semantic_Diagnostic_Feed_Info =>
                     Model.Info_Total := Model.Info_Total + 1;
               end case;
               Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration.Fingerprint (Final));
      return Model;
   end Build_With_Final_Stabilized_Diagnostics;


   function Build_With_Generic_Shared_State_Final_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Final_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Fingerprint (Final),
                Final_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total := Model.Rejected_Total + Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Fingerprint (Final));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Row_Count (Final) loop
         declare
            Final_Row : constant Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Generic_Shared_State_Final_Diagnostic_Row :=
              Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Row_At (Final, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            if Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Is_Emitted (Final_Row.Status) then
               Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
               Feed_Item.Source := Source_Of (Final_Row.Family);
               Feed_Item.Severity := Severity_Of (Final_Row.Severity);
               Feed_Item.Token := Editor.Syntax.Identifier;
               Feed_Item.Node := Final_Row.Node;
               Feed_Item.Message := Final_Row.Message;
               Feed_Item.Start_Line := Final_Row.Start_Line;
               Feed_Item.Start_Column := Final_Row.Start_Column;
               Feed_Item.End_Line := Final_Row.End_Line;
               Feed_Item.End_Column := Final_Row.End_Column;
               Feed_Item.Source_Fingerprint := Final_Row.Diagnostic_Fingerprint;
               Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

               Model.Entries.Append (Feed_Item);
               case Feed_Item.Severity is
                  when Semantic_Diagnostic_Feed_Error =>
                     Model.Error_Total := Model.Error_Total + 1;
                  when Semantic_Diagnostic_Feed_Warning =>
                     Model.Warning_Total := Model.Warning_Total + 1;
                  when Semantic_Diagnostic_Feed_Info =>
                     Model.Info_Total := Model.Info_Total + 1;
               end case;
               Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration.Fingerprint (Final));
      return Model;
   end Build_With_Generic_Shared_State_Final_Diagnostics;


   function Build_With_Generic_Shared_State_RM_Completion_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Final_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.Fingerprint (Final),
                Final_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total := Model.Rejected_Total + Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.Fingerprint (Final));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.Row_Count (Final) loop
         declare
            Final_Row : constant Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.RM_Completion_Diagnostic_Row :=
              Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.Row_At (Final, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            if Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.Is_Emitted (Final_Row.Status) then
               Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
               Feed_Item.Source := Source_Of (Final_Row.Family);
               Feed_Item.Severity := Severity_Of (Final_Row.Severity);
               Feed_Item.Token := Editor.Syntax.Identifier;
               Feed_Item.Node := Final_Row.Node;
               Feed_Item.Message := Final_Row.Message;
               Feed_Item.Start_Line := Final_Row.Start_Line;
               Feed_Item.Start_Column := Final_Row.Start_Column;
               Feed_Item.End_Line := Final_Row.End_Line;
               Feed_Item.End_Column := Final_Row.End_Column;
               Feed_Item.Source_Fingerprint := Final_Row.Diagnostic_Fingerprint;
               Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

               Model.Entries.Append (Feed_Item);
               case Feed_Item.Severity is
                  when Semantic_Diagnostic_Feed_Error =>
                     Model.Error_Total := Model.Error_Total + 1;
                  when Semantic_Diagnostic_Feed_Warning =>
                     Model.Warning_Total := Model.Warning_Total + 1;
                  when Semantic_Diagnostic_Feed_Info =>
                     Model.Info_Total := Model.Info_Total + 1;
               end case;
               Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.Fingerprint (Final));
      return Model;
   end Build_With_Generic_Shared_State_RM_Completion_Diagnostics;


   function Build_With_RM_Completion_Closure_Consumer_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Final_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.Fingerprint (Final),
                Final_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total := Model.Rejected_Total + Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.Fingerprint (Final));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.Row_Count (Final) loop
         declare
            Final_Row : constant Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.RM_Closure_Consumer_Diagnostic_Row :=
              Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.Row_At (Final, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            if Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.Is_Emitted (Final_Row.Status) then
               Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
               Feed_Item.Source := Source_Of (Final_Row.Family);
               Feed_Item.Severity := Severity_Of (Final_Row.Severity);
               Feed_Item.Token := Editor.Syntax.Identifier;
               Feed_Item.Node := Final_Row.Node;
               Feed_Item.Message := Final_Row.Message;
               Feed_Item.Start_Line := Final_Row.Start_Line;
               Feed_Item.Start_Column := Final_Row.Start_Column;
               Feed_Item.End_Line := Final_Row.End_Line;
               Feed_Item.End_Column := Final_Row.End_Column;
               Feed_Item.Source_Fingerprint := Final_Row.Diagnostic_Fingerprint;
               Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

               Model.Entries.Append (Feed_Item);
               case Feed_Item.Severity is
                  when Semantic_Diagnostic_Feed_Error =>
                     Model.Error_Total := Model.Error_Total + 1;
                  when Semantic_Diagnostic_Feed_Warning =>
                     Model.Warning_Total := Model.Warning_Total + 1;
                  when Semantic_Diagnostic_Feed_Info =>
                     Model.Info_Total := Model.Info_Total + 1;
               end case;
               Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.Fingerprint (Final));
      return Model;
   end Build_With_RM_Completion_Closure_Consumer_Diagnostics;



   function Build_With_RM_Completion_Closure_Consumer_Stabilized_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Final_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.Fingerprint (Final),
                Final_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total := Model.Rejected_Total + Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.Fingerprint (Final));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.Row_Count (Final) loop
         declare
            Final_Row : constant Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.RM_Closure_Consumer_Stabilized_Diagnostic_Row :=
              Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.Row_At (Final, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            if Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.Is_Emitted (Final_Row.Status) then
               Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
               Feed_Item.Source := Source_Of (Final_Row.Family);
               Feed_Item.Severity := Severity_Of (Final_Row.Severity);
               Feed_Item.Token := Editor.Syntax.Identifier;
               Feed_Item.Node := Final_Row.Node;
               Feed_Item.Message := Final_Row.Message;
               Feed_Item.Start_Line := Final_Row.Start_Line;
               Feed_Item.Start_Column := Final_Row.Start_Column;
               Feed_Item.End_Line := Final_Row.End_Line;
               Feed_Item.End_Column := Final_Row.End_Column;
               Feed_Item.Source_Fingerprint := Final_Row.Stabilized_Diagnostic_Fingerprint;
               Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

               Model.Entries.Append (Feed_Item);
               case Feed_Item.Severity is
                  when Semantic_Diagnostic_Feed_Error =>
                     Model.Error_Total := Model.Error_Total + 1;
                  when Semantic_Diagnostic_Feed_Warning =>
                     Model.Warning_Total := Model.Warning_Total + 1;
                  when Semantic_Diagnostic_Feed_Info =>
                     Model.Info_Total := Model.Info_Total + 1;
               end case;
               Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration.Fingerprint (Final));
      return Model;
   end Build_With_RM_Completion_Closure_Consumer_Stabilized_Diagnostics;



   function Build_With_Remaining_RM_Edge_Stabilized_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Final_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Fingerprint (Final),
                Final_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total := Model.Rejected_Total + Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Fingerprint (Final));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Row_Count (Final) loop
         declare
            Final_Row : constant Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Diagnostic_Row :=
              Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Row_At (Final, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            if Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Is_Emitted (Final_Row.Status) then
               Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
               Feed_Item.Source := Source_Of (Final_Row.Family);
               Feed_Item.Severity := Severity_Of (Final_Row.Severity);
               Feed_Item.Token := Editor.Syntax.Identifier;
               Feed_Item.Node := Final_Row.Node;
               Feed_Item.Message := Final_Row.Message;
               Feed_Item.Start_Line := Final_Row.Start_Line;
               Feed_Item.Start_Column := Final_Row.Start_Column;
               Feed_Item.End_Line := Final_Row.End_Line;
               Feed_Item.End_Column := Final_Row.End_Column;
               Feed_Item.Source_Fingerprint := Final_Row.Diagnostic_Fingerprint;
               Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

               Model.Entries.Append (Feed_Item);
               case Feed_Item.Severity is
                  when Semantic_Diagnostic_Feed_Error =>
                     Model.Error_Total := Model.Error_Total + 1;
                  when Semantic_Diagnostic_Feed_Warning =>
                     Model.Warning_Total := Model.Warning_Total + 1;
                  when Semantic_Diagnostic_Feed_Info =>
                     Model.Info_Total := Model.Info_Total + 1;
               end case;
               Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Remaining_RM_Edge_Stabilized_Diagnostic_Integration.Fingerprint (Final));
      return Model;
   end Build_With_Remaining_RM_Edge_Stabilized_Diagnostics;


   function Build_With_Remaining_RM_Edge_Stabilized_Closure_Diagnostics
     (Guarded : Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
      Final   : Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Final_Input_Current : Boolean := True;
      Final_Rejected_Count : Natural := 0)
      return Semantic_Diagnostic_Feed_Model
   is
      Model : Semantic_Diagnostic_Feed_Model := Build (Guarded);
   begin
      if not Final_Input_Current then
         Clear (Model);
         Model.Feed_Status := Semantic_Diagnostic_Feed_Rejected_Stale;
         Model.Rejected_Total := Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Fingerprint (Final),
                Final_Rejected_Count + 1);
         return Model;
      end if;

      if Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale then
         Model.Rejected_Total := Model.Rejected_Total + Final_Rejected_Count;
         Model.Result_Fingerprint :=
           Mix (Model.Result_Fingerprint,
                Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Fingerprint (Final));
         return Model;
      end if;

      for Index in 1 .. Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Row_Count (Final) loop
         declare
            Final_Row : constant Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row :=
              Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Row_At (Final, Index);
            Feed_Item : Semantic_Diagnostic_Feed_Entry;
         begin
            if Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Is_Emitted (Final_Row.Status) then
               Feed_Item.Id := Semantic_Diagnostic_Feed_Id (Natural (Model.Entries.Length) + 1);
               Feed_Item.Source := Source_Of (Final_Row.Family);
               Feed_Item.Severity := Severity_Of (Final_Row.Severity);
               Feed_Item.Token := Editor.Syntax.Identifier;
               Feed_Item.Node := Final_Row.Node;
               Feed_Item.Message := Final_Row.Message;
               Feed_Item.Start_Line := Final_Row.Start_Line;
               Feed_Item.Start_Column := Final_Row.Start_Column;
               Feed_Item.End_Line := Final_Row.End_Line;
               Feed_Item.End_Column := Final_Row.End_Column;
               Feed_Item.Source_Fingerprint := Final_Row.Diagnostic_Fingerprint;
               Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);

               Model.Entries.Append (Feed_Item);
               case Feed_Item.Severity is
                  when Semantic_Diagnostic_Feed_Error =>
                     Model.Error_Total := Model.Error_Total + 1;
                  when Semantic_Diagnostic_Feed_Warning =>
                     Model.Warning_Total := Model.Warning_Total + 1;
                  when Semantic_Diagnostic_Feed_Info =>
                     Model.Info_Total := Model.Info_Total + 1;
               end case;
               Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration.Fingerprint (Final));
      return Model;
   end Build_With_Remaining_RM_Edge_Stabilized_Closure_Diagnostics;

   function Status (Model : Semantic_Diagnostic_Feed_Model) return Semantic_Diagnostic_Feed_Status is
   begin
      return Model.Feed_Status;
   end Status;

   function Current (Model : Semantic_Diagnostic_Feed_Model) return Boolean is
   begin
      return Model.Feed_Status = Semantic_Diagnostic_Feed_Current;
   end Current;

   function Rejected_Stale (Model : Semantic_Diagnostic_Feed_Model) return Boolean is
   begin
      return Model.Feed_Status = Semantic_Diagnostic_Feed_Rejected_Stale;
   end Rejected_Stale;

   function Entry_Count (Model : Semantic_Diagnostic_Feed_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Entry_Count;

   function Entry_At
     (Model : Semantic_Diagnostic_Feed_Model;
      Index : Positive) return Semantic_Diagnostic_Feed_Entry
   is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Entry_At;

   function Error_Count (Model : Semantic_Diagnostic_Feed_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Semantic_Diagnostic_Feed_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Semantic_Diagnostic_Feed_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Count_Source
     (Model  : Semantic_Diagnostic_Feed_Model;
      Source : Semantic_Diagnostic_Feed_Source) return Natural
   is
      Total : Natural := 0;
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Source = Source then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Source;

   function Count_Token
     (Model : Semantic_Diagnostic_Feed_Model;
      Token : Editor.Syntax.Token_Kind) return Natural
   is
      Total : Natural := 0;
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Token = Token then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Token;

   function Rejected_Entry_Count (Model : Semantic_Diagnostic_Feed_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Entry_Count;

   function Fingerprint (Model : Semantic_Diagnostic_Feed_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Semantic_Diagnostic_Feed;
