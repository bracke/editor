with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_View_Aware_Compatibility;
with Editor.Ada_Dispatching_Call_Legality;
with Editor.Ada_Overload_Ranking;

package body Editor.Ada_Expression_Diagnostics is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Status;
   use type Editor.Ada_Overload_Ranking.Overload_Ranking_Status;

   function Mix (Left : Natural; Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 97) mod 2_147_483_647;
   end Mix;

   function Severity_Fingerprint
     (Severity : Expression_Diagnostic_Severity) return Natural is
   begin
      return Expression_Diagnostic_Severity'Pos (Severity) + 1;
   end Severity_Fingerprint;

   function Kind_Fingerprint
     (Kind : Expression_Diagnostic_Kind) return Natural is
   begin
      return Expression_Diagnostic_Kind'Pos (Kind) + 1;
   end Kind_Fingerprint;

   function Text_For_Kind (Kind : Expression_Diagnostic_Kind) return String is
   begin
      case Kind is
         when Expression_Diagnostic_Expected_Type_Mismatch =>
            return "expression does not match the expected subtype";
         when Expression_Diagnostic_Operator_Operand_Mismatch =>
            return "operator operand subtypes are incompatible";
         when Expression_Diagnostic_Operator_Ambiguous =>
            return "operator overload resolution is ambiguous";
         when Expression_Diagnostic_Call_Actual_Mismatch =>
            return "call actual subtype does not match the formal subtype";
         when Expression_Diagnostic_Call_Ambiguous =>
            return "call resolution remains ambiguous";
         when Expression_Diagnostic_Aggregate_Mismatch =>
            return "aggregate does not match its expected aggregate subtype";
         when Expression_Diagnostic_Conversion_Mismatch =>
            return "conversion or qualified expression operand is incompatible";
         when Expression_Diagnostic_Membership_Mismatch =>
            return "membership operand and choice subtypes are incompatible";
         when Expression_Diagnostic_Range_Mismatch =>
            return "range bounds have incompatible subtypes";
         when Expression_Diagnostic_Dereference_Target_Error =>
            return "dereference prefix is not an access type";
         when Expression_Diagnostic_Allocator_Target_Error =>
            return "allocator target does not match the expected access type";
         when Expression_Diagnostic_Boolean_Context_Mismatch =>
            return "expression is not compatible with a Boolean context";
         when Expression_Diagnostic_Universal_Numeric_Range_Error =>
            return "static universal numeric value is outside the expected subtype range";
         when Expression_Diagnostic_Concatenation_Mismatch =>
            return "concatenation operands are incompatible";
         when Expression_Diagnostic_Unresolved_Expression =>
            return "expression name or target could not be resolved";
         when Expression_Diagnostic_Unknown_Expression =>
            return "expression type is unknown";
      end case;
   end Text_For_Kind;

   function Severity_From_Cause
     (Severity : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Severity)
      return Expression_Diagnostic_Severity
   is
   begin
      case Severity is
         when Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Error =>
            return Expression_Diagnostic_Error;
         when Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Warning =>
            return Expression_Diagnostic_Warning;
         when Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Info =>
            return Expression_Diagnostic_Severity_Info;
      end case;
   end Severity_From_Cause;

   function Kind_From_Cause
     (Kind : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Kind)
      return Expression_Diagnostic_Kind
   is
   begin
      case Kind is
         when Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Call_Actual_Mismatch =>
            return Expression_Diagnostic_Call_Actual_Mismatch;
         when Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Call_Ambiguous |
              Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Call_Profile_Unavailable =>
            return Expression_Diagnostic_Call_Ambiguous;
         when Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Call_Unresolved =>
            return Expression_Diagnostic_Unresolved_Expression;
         when Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Operator_Ambiguous |
              Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Operator_Overload_Ambiguous =>
            return Expression_Diagnostic_Operator_Ambiguous;
         when Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Operator_Operand_Mismatch |
              Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Operator_Overload_Mismatch =>
            return Expression_Diagnostic_Operator_Operand_Mismatch;
         when Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Universal_Numeric_Range_Error =>
            return Expression_Diagnostic_Universal_Numeric_Range_Error;
         when Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Universal_Numeric_Mismatch =>
            return Expression_Diagnostic_Expected_Type_Mismatch;
         when others =>
            return Expression_Diagnostic_Unknown_Expression;
      end case;
   end Kind_From_Cause;


   function View_Severity
     (Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status)
      return Expression_Diagnostic_Severity
   is
   begin
      case Status is
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Known_Incompatible =>
            return Expression_Diagnostic_Error;
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Compatible |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View =>
            return Expression_Diagnostic_Severity_Info;
         when others =>
            return Expression_Diagnostic_Warning;
      end case;
   end View_Severity;

   function View_Kind
     (Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status)
      return Expression_Diagnostic_Kind
   is
   begin
      case Status is
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Known_Incompatible =>
            return Expression_Diagnostic_Expected_Type_Mismatch;
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Indeterminate =>
            return Expression_Diagnostic_Unknown_Expression;
         when others =>
            return Expression_Diagnostic_Unresolved_Expression;
      end case;
   end View_Kind;

   function View_Message
     (Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status)
      return String
   is
   begin
      case Status is
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Partial_View =>
            return "private partial view participates in compatibility";
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View =>
            return "private full view is visible for compatibility";
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View_Hidden =>
            return "private full view is hidden from this compatibility context";
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Limited_Incomplete_View =>
            return "limited with exposes only an incomplete view";
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Limited_Full_View_Hidden =>
            return "limited with hides the full view in this context";
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Private_View =>
            return "cross-unit selected name resolves through a private view";
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Unresolved =>
            return "cross-unit selected-name compatibility could not be resolved";
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Known_Incompatible =>
            return "view-aware subtype compatibility is known to be incompatible";
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Indeterminate =>
            return "view-aware subtype compatibility is indeterminate";
         when others =>
            return "view-aware compatibility metadata was projected";
      end case;
   end View_Message;

   function View_Status_Fingerprint
     (Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status)
      return Natural
   is
   begin
      return Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status'Pos (Status) + 1;
   end View_Status_Fingerprint;




   function Ranking_Status_Fingerprint
     (Status : Editor.Ada_Overload_Ranking.Overload_Ranking_Status)
      return Natural is
   begin
      return Editor.Ada_Overload_Ranking.Overload_Ranking_Status'Pos (Status) + 1;
   end Ranking_Status_Fingerprint;

   function Severity_From_Ranking
     (Status : Editor.Ada_Overload_Ranking.Overload_Ranking_Status)
      return Expression_Diagnostic_Severity is
   begin
      case Status is
         when Editor.Ada_Overload_Ranking.Overload_Ranking_Ambiguous_After_Ranking |
              Editor.Ada_Overload_Ranking.Overload_Ranking_No_Ranked_Candidate =>
            return Expression_Diagnostic_Error;
         when Editor.Ada_Overload_Ranking.Overload_Ranking_Unknown =>
            return Expression_Diagnostic_Warning;
         when others =>
            return Expression_Diagnostic_Severity_Info;
      end case;
   end Severity_From_Ranking;

   function Kind_From_Ranking
     (Status : Editor.Ada_Overload_Ranking.Overload_Ranking_Status)
      return Expression_Diagnostic_Kind is
   begin
      case Status is
         when Editor.Ada_Overload_Ranking.Overload_Ranking_Ambiguous_After_Ranking =>
            return Expression_Diagnostic_Call_Ambiguous;
         when Editor.Ada_Overload_Ranking.Overload_Ranking_No_Ranked_Candidate =>
            return Expression_Diagnostic_Call_Actual_Mismatch;
         when Editor.Ada_Overload_Ranking.Overload_Ranking_Unknown =>
            return Expression_Diagnostic_Unknown_Expression;
         when others =>
            return Expression_Diagnostic_Unknown_Expression;
      end case;
   end Kind_From_Ranking;

   procedure Add_Overload_Ranking
     (Model  : in out Expression_Diagnostic_Model;
      Source : Editor.Ada_Overload_Ranking.Overload_Ranking_Info)
   is
      Id : constant Expression_Diagnostic_Id :=
        Expression_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Item : Expression_Diagnostic_Info;
      Kind : constant Expression_Diagnostic_Kind := Kind_From_Ranking (Source.Status);
      Sev  : constant Expression_Diagnostic_Severity := Severity_From_Ranking (Source.Status);
   begin
      if not Editor.Ada_Overload_Ranking.Has_Ranking (Source) then
         return;
      end if;

      --  Successful exact, implicit-conversion, and universal-numeric ranking
      --  results remain provenance metadata.  Only unresolved, rejected, or
      --  still-ambiguous ranking states become diagnostics.
      if Sev = Expression_Diagnostic_Severity_Info then
         return;
      end if;

      Item.Id := Id;
      Item.Node := Source.Node;
      Item.Kind := Kind;
      Item.Severity := Sev;
      Item.Message := Source.Message;
      Item.Detail := Source.Detail;
      Item.From_Overload_Ranking := True;
      Item.Overload_Ranking := Source.Id;
      Item.Overload_Ranking_Status := Source.Status;
      Item.Candidate_Count := Source.Candidate_Count;
      Item.Selected_Count := Source.Selected_Count;
      Item.Compatible_Count := Source.Exact_Match_Count + Source.Implicit_Conversion_Count +
        Source.Universal_Numeric_Count;
      Item.Mismatch_Count := Source.Rejected_Count;
      Item.Unknown_Count := Source.Unknown_Count;
      Item.Overload_Ranking_Fingerprint := Source.Fingerprint;
      Item.Start_Line := Source.Start_Line;
      Item.Start_Column := Source.Start_Column;
      Item.End_Line := Source.End_Line;
      Item.End_Column := Source.End_Column;
      Item.Fingerprint := Mix
        (Mix (Natural (Source.Node), Source.Fingerprint),
         Mix (Kind_Fingerprint (Kind),
              Mix (Severity_Fingerprint (Sev), Ranking_Status_Fingerprint (Source.Status))));

      Model.Diagnostics.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);
   end Add_Overload_Ranking;

   function Dispatching_Status_Fingerprint
     (Status : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Status)
      return Natural is
   begin
      return Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Status'Pos (Status) + 1;
   end Dispatching_Status_Fingerprint;

   procedure Add_View_Compatibility
     (Model  : in out Expression_Diagnostic_Model;
      Source : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info)
   is
      use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
      use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Id;
      Id : constant Expression_Diagnostic_Id :=
        Expression_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Item : Expression_Diagnostic_Info;
      Kind : constant Expression_Diagnostic_Kind := View_Kind (Source.Status);
      Sev  : constant Expression_Diagnostic_Severity := View_Severity (Source.Status);
   begin
      if Source.Id = Editor.Ada_View_Aware_Compatibility.No_View_Compatibility
        or else Source.Status = Editor.Ada_View_Aware_Compatibility.View_Compatibility_Not_Checked
        or else Source.Status = Editor.Ada_View_Aware_Compatibility.View_Compatibility_Compatible
      then
         return;
      end if;

      Item.Id := Id;
      Item.Node := Source.Node;
      Item.Kind := Kind;
      Item.Severity := Sev;
      Item.Message := To_Unbounded_String (View_Message (Source.Status));
      Item.Detail := To_Unbounded_String
        ("expected='" & To_String (Source.Expected_Subtype)
         & "' actual='" & To_String (Source.Actual_Subtype)
         & "' target='" & To_String (Source.Cross_Unit_Target)
         & "' selector='" & To_String (Source.Cross_Unit_Selector) & "'");
      Item.From_View_Compatibility := True;
      Item.View_Compatibility := Source.Id;
      Item.View_Status := Source.Status;
      Item.View_Fingerprint := Source.Fingerprint;
      Item.Start_Line := Source.Start_Line;
      Item.Start_Column := 1;
      Item.End_Line := Source.End_Line;
      Item.End_Column := 1;
      Item.Fingerprint := Mix
        (Mix (Natural (Source.Node), Source.Fingerprint),
         Mix (Kind_Fingerprint (Kind),
              Mix (Severity_Fingerprint (Sev), View_Status_Fingerprint (Source.Status))));

      Model.Diagnostics.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);
   end Add_View_Compatibility;

   function Severity_From_Dispatching
     (Status : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Status)
      return Expression_Diagnostic_Severity is
   begin
      case Status is
         when Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Target_Unresolved |
              Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Target_Ambiguous |
              Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Controlling_Unknown |
              Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Abstract_Unknown =>
            return Expression_Diagnostic_Error;
         when Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Indeterminate =>
            return Expression_Diagnostic_Warning;
         when others =>
            return Expression_Diagnostic_Severity_Info;
      end case;
   end Severity_From_Dispatching;

   function Kind_From_Dispatching
     (Status : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Status)
      return Expression_Diagnostic_Kind is
   begin
      case Status is
         when Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Target_Ambiguous =>
            return Expression_Diagnostic_Call_Ambiguous;
         when Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Target_Unresolved =>
            return Expression_Diagnostic_Unresolved_Expression;
         when Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Controlling_Unknown |
              Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Abstract_Unknown |
              Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Indeterminate =>
            return Expression_Diagnostic_Unknown_Expression;
         when others =>
            return Expression_Diagnostic_Unknown_Expression;
      end case;
   end Kind_From_Dispatching;

   procedure Add_Dispatching_Legality
     (Model  : in out Expression_Diagnostic_Model;
      Source : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Info)
   is
      Id : constant Expression_Diagnostic_Id :=
        Expression_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Item : Expression_Diagnostic_Info;
      Kind : constant Expression_Diagnostic_Kind := Kind_From_Dispatching (Source.Status);
      Sev  : constant Expression_Diagnostic_Severity := Severity_From_Dispatching (Source.Status);
   begin
      if not Editor.Ada_Dispatching_Call_Legality.Has_Legality (Source) then
         return;
      end if;

      --  Resolved dispatching classifications are provenance/informational
      --  metadata; only warning/error states become expression diagnostics.
      if Sev = Expression_Diagnostic_Severity_Info then
         return;
      end if;

      Item.Id := Id;
      Item.Node := Source.Node;
      Item.Kind := Kind;
      Item.Severity := Sev;
      Item.Message := Source.Message;
      Item.Detail := Source.Detail;
      Item.From_Dispatching_Legality := True;
      Item.Dispatching_Legality := Source.Id;
      Item.Dispatching_Status := Source.Status;
      Item.Candidate_Count := Source.Primitive_Count;
      Item.Selected_Count := Source.Controlling_Operand_Count + Source.Controlling_Result_Count;
      Item.Compatible_Count := Natural (Boolean'Pos
        (Source.Status in Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Static_Binding |
          Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Dynamic_Dispatch |
          Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Controlling_Result |
          Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Primitive_Target));
      Item.Mismatch_Count := Source.Ambiguous_Count;
      Item.Unknown_Count := Source.Unknown_Count;
      Item.Dispatching_Fingerprint := Source.Fingerprint;
      Item.Start_Line := Source.Start_Line;
      Item.Start_Column := Source.Start_Column;
      Item.End_Line := Source.End_Line;
      Item.End_Column := Source.End_Column;
      Item.Fingerprint := Mix
        (Mix (Natural (Source.Node), Source.Fingerprint),
         Mix (Kind_Fingerprint (Kind),
              Mix (Severity_Fingerprint (Sev), Dispatching_Status_Fingerprint (Source.Status))));

      Model.Diagnostics.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);
   end Add_Dispatching_Legality;

   procedure Add_Overload_Cause
     (Model  : in out Expression_Diagnostic_Model;
      Source : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Diagnostic)
   is
      Id : constant Expression_Diagnostic_Id :=
        Expression_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Item : Expression_Diagnostic_Info;
      Kind : constant Expression_Diagnostic_Kind := Kind_From_Cause (Source.Kind);
      Sev  : constant Expression_Diagnostic_Severity := Severity_From_Cause (Source.Severity);
   begin
      if not Editor.Ada_Overload_Ambiguity_Diagnostics.Has_Diagnostic (Source) then
         return;
      end if;

      Item.Id := Id;
      Item.Node := Source.Node;
      Item.Kind := Kind;
      Item.Severity := Sev;
      Item.Message := Source.Message;
      Item.Detail := Source.Detail;
      Item.From_Overload_Cause := True;
      Item.Candidate_Count := Source.Candidate_Count;
      Item.Selected_Count := Source.Selected_Count;
      Item.Compatible_Count := Source.Compatible_Count;
      Item.Mismatch_Count := Source.Mismatch_Count;
      Item.Unknown_Count := Source.Unknown_Count;
      Item.Cause_Fingerprint := Source.Fingerprint;
      Item.Start_Line := Source.Start_Line;
      Item.Start_Column := Source.Start_Column;
      Item.End_Line := Source.End_Line;
      Item.End_Column := Source.End_Column;
      Item.Fingerprint := Mix
        (Mix (Natural (Source.Node), Source.Fingerprint),
         Mix (Kind_Fingerprint (Kind), Severity_Fingerprint (Sev)));

      Model.Diagnostics.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);
   end Add_Overload_Cause;

   procedure Add_Diagnostic
     (Model    : in out Expression_Diagnostic_Model;
      Source   : Editor.Ada_Expression_Types.Expression_Type_Info;
      Kind     : Expression_Diagnostic_Kind;
      Severity : Expression_Diagnostic_Severity)
   is
      Id : constant Expression_Diagnostic_Id :=
        Expression_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Line_Start : constant Positive := Source.Start_Line;
      Line_End   : constant Positive := Source.End_Line;
      Item : Expression_Diagnostic_Info;
   begin
      Item.Id := Id;
      Item.Node := Source.Node;
      Item.Kind := Kind;
      Item.Severity := Severity;
      Item.Message := To_Unbounded_String (Text_For_Kind (Kind));
      Item.Start_Line := Line_Start;
      Item.Start_Column := 1;
      Item.End_Line := Line_End;
      Item.End_Column := 1;
      Item.Fingerprint := Mix
        (Mix (Natural (Source.Node), Natural (Line_Start)),
         Mix (Kind_Fingerprint (Kind), Severity_Fingerprint (Severity)));

      Model.Diagnostics.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);
   end Add_Diagnostic;

   function First_Diagnostic_Kind
     (Info  : Editor.Ada_Expression_Types.Expression_Type_Info;
      Kind  : out Expression_Diagnostic_Kind;
      Sev   : out Expression_Diagnostic_Severity) return Boolean
   is
      use type Editor.Ada_Expression_Types.Expected_Type_Propagation_Status;
      use type Editor.Ada_Expression_Types.Operator_Type_Inference_Status;
      use type Editor.Ada_Expression_Types.Call_Actual_Type_Resolution_Status;
      use type Editor.Ada_Expression_Types.Aggregate_Type_Inference_Status;
      use type Editor.Ada_Expression_Types.Conversion_Type_Inference_Status;
      use type Editor.Ada_Expression_Types.Membership_Range_Inference_Status;
      use type Editor.Ada_Expression_Types.Dereference_Access_Inference_Status;
      use type Editor.Ada_Expression_Types.Allocator_Type_Inference_Status;
      use type Editor.Ada_Expression_Types.Boolean_Context_Inference_Status;
      use type Editor.Ada_Expression_Types.Universal_Numeric_Resolution_Status;
      use type Editor.Ada_Expression_Types.Concatenation_Type_Inference_Status;
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
   begin
      Sev := Expression_Diagnostic_Error;

      if Info.Expected_Status = Editor.Ada_Expression_Types.Expected_Type_Mismatch then
         Kind := Expression_Diagnostic_Expected_Type_Mismatch;
         return True;
      elsif Info.Operator_Status = Editor.Ada_Expression_Types.Operator_Type_Operand_Mismatch
        or else Info.Operator_Status = Editor.Ada_Expression_Types.Operator_Type_Overload_Mismatch
      then
         Kind := Expression_Diagnostic_Operator_Operand_Mismatch;
         return True;
      elsif Info.Operator_Status = Editor.Ada_Expression_Types.Operator_Type_Ambiguous
        or else Info.Operator_Status = Editor.Ada_Expression_Types.Operator_Type_Overload_Ambiguous
      then
         Kind := Expression_Diagnostic_Operator_Ambiguous;
         return True;
      elsif Info.Call_Actual_Type_Status = Editor.Ada_Expression_Types.Call_Actual_Type_Actual_Mismatch then
         Kind := Expression_Diagnostic_Call_Actual_Mismatch;
         return True;
      elsif Info.Call_Actual_Type_Status = Editor.Ada_Expression_Types.Call_Actual_Type_Ambiguous_Call then
         Kind := Expression_Diagnostic_Call_Ambiguous;
         return True;
      elsif Info.Aggregate_Status in
        Editor.Ada_Expression_Types.Aggregate_Type_Record_Component_Missing |
        Editor.Ada_Expression_Types.Aggregate_Type_Record_Component_Duplicate |
        Editor.Ada_Expression_Types.Aggregate_Type_Array_Element_Mismatch |
        Editor.Ada_Expression_Types.Aggregate_Type_Mismatch
      then
         Kind := Expression_Diagnostic_Aggregate_Mismatch;
         return True;
      elsif Info.Conversion_Status = Editor.Ada_Expression_Types.Conversion_Type_Operand_Mismatch then
         Kind := Expression_Diagnostic_Conversion_Mismatch;
         return True;
      elsif Info.Membership_Range_Status = Editor.Ada_Expression_Types.Membership_Range_Membership_Mismatch then
         Kind := Expression_Diagnostic_Membership_Mismatch;
         return True;
      elsif Info.Membership_Range_Status = Editor.Ada_Expression_Types.Membership_Range_Range_Mismatch then
         Kind := Expression_Diagnostic_Range_Mismatch;
         return True;
      elsif Info.Dereference_Access_Status = Editor.Ada_Expression_Types.Dereference_Prefix_Not_Access_Type then
         Kind := Expression_Diagnostic_Dereference_Target_Error;
         return True;
      elsif Info.Allocator_Status in
        Editor.Ada_Expression_Types.Allocator_Type_Expected_Not_Access |
        Editor.Ada_Expression_Types.Allocator_Type_Designated_Mismatch
      then
         Kind := Expression_Diagnostic_Allocator_Target_Error;
         return True;
      elsif Info.Boolean_Context_Status in
        Editor.Ada_Expression_Types.Boolean_Context_Operand_Mismatch |
        Editor.Ada_Expression_Types.Boolean_Context_Short_Circuit_Mismatch |
        Editor.Ada_Expression_Types.Boolean_Context_Condition_Mismatch
      then
         Kind := Expression_Diagnostic_Boolean_Context_Mismatch;
         return True;
      elsif Info.Universal_Numeric_Status = Editor.Ada_Expression_Types.Universal_Numeric_Range_Error then
         Kind := Expression_Diagnostic_Universal_Numeric_Range_Error;
         return True;
      elsif Info.Concatenation_Status = Editor.Ada_Expression_Types.Concatenation_Type_Operand_Mismatch then
         Kind := Expression_Diagnostic_Concatenation_Mismatch;
         return True;
      elsif Info.Status in
        Editor.Ada_Expression_Types.Expression_Type_Name_Unresolved |
        Editor.Ada_Expression_Types.Expression_Type_Selected_Name_Unresolved |
        Editor.Ada_Expression_Types.Expression_Type_Selected_Name_Cross_Unit_Limited |
        Editor.Ada_Expression_Types.Expression_Type_Selected_Name_Cross_Unit_Private |
        Editor.Ada_Expression_Types.Expression_Type_Selected_Name_Cross_Unit_Unresolved |
        Editor.Ada_Expression_Types.Expression_Type_Call_Unresolved
      then
         Kind := Expression_Diagnostic_Unresolved_Expression;
         Sev := Expression_Diagnostic_Warning;
         return True;
      elsif Info.Status in
        Editor.Ada_Expression_Types.Expression_Type_Operator_Unknown |
        Editor.Ada_Expression_Types.Expression_Type_Indeterminate |
        Editor.Ada_Expression_Types.Expression_Type_Malformed
      then
         Kind := Expression_Diagnostic_Unknown_Expression;
         Sev := Expression_Diagnostic_Warning;
         return True;
      end if;

      return False;
   end First_Diagnostic_Kind;

   procedure Clear (Model : in out Expression_Diagnostic_Model) is
   begin
      Model.Diagnostics.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return Expression_Diagnostic_Model
   is
      Model : Expression_Diagnostic_Model;
      Kind  : Expression_Diagnostic_Kind;
      Sev   : Expression_Diagnostic_Severity;
      Info  : Editor.Ada_Expression_Types.Expression_Type_Info;
   begin
      for I in 1 .. Editor.Ada_Expression_Types.Expression_Type_Count (Expressions) loop
         Info := Editor.Ada_Expression_Types.Expression_Type_At (Expressions, I);
         if First_Diagnostic_Kind (Info, Kind, Sev) then
            Add_Diagnostic (Model, Info, Kind, Sev);
         end if;
      end loop;
      return Model;
   end Build;

   function Build_With_Overload_Causes
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes      : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model)
      return Expression_Diagnostic_Model
   is
      Model : Expression_Diagnostic_Model := Build (Expressions);
      Cause : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Diagnostic;
   begin
      for I in 1 .. Editor.Ada_Overload_Ambiguity_Diagnostics.Diagnostic_Count (Causes) loop
         Cause := Editor.Ada_Overload_Ambiguity_Diagnostics.Diagnostic_At (Causes, I);
         Add_Overload_Cause (Model, Cause);
      end loop;
      return Model;
   end Build_With_Overload_Causes;


   function Build_With_View_Compatibility
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Views       : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model)
      return Expression_Diagnostic_Model
   is
      Model : Expression_Diagnostic_Model := Build (Expressions);
      View  : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info;
   begin
      for I in 1 .. Editor.Ada_View_Aware_Compatibility.Entry_Count (Views) loop
         View := Editor.Ada_View_Aware_Compatibility.Entry_At (Views, I);
         Add_View_Compatibility (Model, View);
      end loop;
      return Model;
   end Build_With_View_Compatibility;

   function Build_With_Overload_Causes_And_View_Compatibility
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes      : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
      Views       : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model)
      return Expression_Diagnostic_Model
   is
      Model : Expression_Diagnostic_Model := Build_With_Overload_Causes (Expressions, Causes);
      View  : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info;
   begin
      for I in 1 .. Editor.Ada_View_Aware_Compatibility.Entry_Count (Views) loop
         View := Editor.Ada_View_Aware_Compatibility.Entry_At (Views, I);
         Add_View_Compatibility (Model, View);
      end loop;
      return Model;
   end Build_With_Overload_Causes_And_View_Compatibility;


   function Build_With_Overload_Ranking
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Ranking     : Editor.Ada_Overload_Ranking.Overload_Ranking_Model)
      return Expression_Diagnostic_Model
   is
      Model : Expression_Diagnostic_Model := Build (Expressions);
      Item  : Editor.Ada_Overload_Ranking.Overload_Ranking_Info;
   begin
      for I in 1 .. Editor.Ada_Overload_Ranking.Ranking_Count (Ranking) loop
         Item := Editor.Ada_Overload_Ranking.Ranking_At (Ranking, I);
         Add_Overload_Ranking (Model, Item);
      end loop;
      return Model;
   end Build_With_Overload_Ranking;

   function Build_With_Dispatching_Legality
     (Expressions  : Editor.Ada_Expression_Types.Expression_Type_Model;
      Dispatching : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model)
      return Expression_Diagnostic_Model
   is
      Model : Expression_Diagnostic_Model := Build (Expressions);
      Item  : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Info;
   begin
      for I in 1 .. Editor.Ada_Dispatching_Call_Legality.Legality_Count (Dispatching) loop
         Item := Editor.Ada_Dispatching_Call_Legality.Legality_At (Dispatching, I);
         Add_Dispatching_Legality (Model, Item);
      end loop;
      return Model;
   end Build_With_Dispatching_Legality;

   function Build_With_All_Semantic_Causes
     (Expressions  : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes       : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
      Views        : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Dispatching  : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model)
      return Expression_Diagnostic_Model
   is
      Model : Expression_Diagnostic_Model :=
        Build_With_Overload_Causes_And_View_Compatibility (Expressions, Causes, Views);
      Item  : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Info;
   begin
      for I in 1 .. Editor.Ada_Dispatching_Call_Legality.Legality_Count (Dispatching) loop
         Item := Editor.Ada_Dispatching_Call_Legality.Legality_At (Dispatching, I);
         Add_Dispatching_Legality (Model, Item);
      end loop;
      return Model;
   end Build_With_All_Semantic_Causes;

   function Build_With_All_Semantic_Causes_And_Ranking
     (Expressions  : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes       : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
      Views        : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Dispatching  : Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model;
      Ranking      : Editor.Ada_Overload_Ranking.Overload_Ranking_Model)
      return Expression_Diagnostic_Model
   is
      Model : Expression_Diagnostic_Model :=
        Build_With_All_Semantic_Causes (Expressions, Causes, Views, Dispatching);
      Item  : Editor.Ada_Overload_Ranking.Overload_Ranking_Info;
   begin
      for I in 1 .. Editor.Ada_Overload_Ranking.Ranking_Count (Ranking) loop
         Item := Editor.Ada_Overload_Ranking.Ranking_At (Ranking, I);
         Add_Overload_Ranking (Model, Item);
      end loop;
      return Model;
   end Build_With_All_Semantic_Causes_And_Ranking;

   function Has_Diagnostics (Model : Expression_Diagnostic_Model) return Boolean is
   begin
      return not Model.Diagnostics.Is_Empty;
   end Has_Diagnostics;

   function Diagnostic_Count (Model : Expression_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Diagnostics.Length);
   end Diagnostic_Count;

   function Diagnostic_At
     (Model : Expression_Diagnostic_Model;
      Index : Positive) return Expression_Diagnostic_Info is
   begin
      if Index > Natural (Model.Diagnostics.Length) then
         return (others => <>);
      end if;
      return Model.Diagnostics.Element (Index);
   end Diagnostic_At;

   function Diagnostic_For_Node
     (Model : Expression_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expression_Diagnostic_Info is
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).Node = Node then
            return Model.Diagnostics.Element (Positive (I));
         end if;
      end loop;
      return (others => <>);
   end Diagnostic_For_Node;

   function Count_Severity
     (Model    : Expression_Diagnostic_Model;
      Severity : Expression_Diagnostic_Severity) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).Severity = Severity then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Severity;

   function Error_Count (Model : Expression_Diagnostic_Model) return Natural is
   begin
      return Count_Severity (Model, Expression_Diagnostic_Error);
   end Error_Count;

   function Warning_Count (Model : Expression_Diagnostic_Model) return Natural is
   begin
      return Count_Severity (Model, Expression_Diagnostic_Warning);
   end Warning_Count;

   function Info_Count (Model : Expression_Diagnostic_Model) return Natural is
   begin
      return Count_Severity (Model, Expression_Diagnostic_Severity_Info);
   end Info_Count;

   function Count_Kind
     (Model : Expression_Diagnostic_Model;
      Kind  : Expression_Diagnostic_Kind) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).Kind = Kind then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Kind;


   function Overload_Cause_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_Overload_Cause then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Overload_Cause_Diagnostic_Count;

   function Candidate_Rejection_Count
     (Model : Expression_Diagnostic_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_Overload_Cause then
            Result := Result + Model.Diagnostics.Element (Positive (I)).Mismatch_Count;
         end if;
      end loop;
      return Result;
   end Candidate_Rejection_Count;


   function View_Compatibility_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_View_Compatibility then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end View_Compatibility_Diagnostic_Count;

   function Private_View_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural
   is
      use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
      Result : Natural := 0;
      Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         Status := Model.Diagnostics.Element (Positive (I)).View_Status;
         if Model.Diagnostics.Element (Positive (I)).From_View_Compatibility
           and then Status in
             Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Partial_View |
             Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View |
             Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View_Hidden |
             Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Private_View
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Private_View_Diagnostic_Count;

   function Limited_View_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural
   is
      use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
      Result : Natural := 0;
      Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         Status := Model.Diagnostics.Element (Positive (I)).View_Status;
         if Model.Diagnostics.Element (Positive (I)).From_View_Compatibility
           and then Status in
             Editor.Ada_View_Aware_Compatibility.View_Compatibility_Limited_Incomplete_View |
             Editor.Ada_View_Aware_Compatibility.View_Compatibility_Limited_Full_View_Hidden
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Limited_View_Diagnostic_Count;

   function View_Unresolved_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural
   is
      use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_View_Compatibility
           and then Model.Diagnostics.Element (Positive (I)).View_Status =
             Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Unresolved
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end View_Unresolved_Diagnostic_Count;


   function Dispatching_Legality_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_Dispatching_Legality then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Dispatching_Legality_Diagnostic_Count;

   function Dispatching_Dynamic_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_Dispatching_Legality
           and then Model.Diagnostics.Element (Positive (I)).Dispatching_Status =
             Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Dynamic_Dispatch
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Dispatching_Dynamic_Diagnostic_Count;

   function Dispatching_Static_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_Dispatching_Legality
           and then Model.Diagnostics.Element (Positive (I)).Dispatching_Status =
             Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Static_Binding
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Dispatching_Static_Diagnostic_Count;

   function Dispatching_Unresolved_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_Dispatching_Legality
           and then Model.Diagnostics.Element (Positive (I)).Dispatching_Status in
             Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Target_Unresolved |
             Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Target_Ambiguous |
             Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Controlling_Unknown |
             Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Abstract_Unknown |
             Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Indeterminate
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Dispatching_Unresolved_Diagnostic_Count;



   function Overload_Ranking_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_Overload_Ranking then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Overload_Ranking_Diagnostic_Count;

   function Overload_Ranking_Ambiguous_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_Overload_Ranking
           and then Model.Diagnostics.Element (Positive (I)).Overload_Ranking_Status =
             Editor.Ada_Overload_Ranking.Overload_Ranking_Ambiguous_After_Ranking
         then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Overload_Ranking_Ambiguous_Diagnostic_Count;

   function Overload_Ranking_Rejection_Diagnostic_Count
     (Model : Expression_Diagnostic_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Diagnostics.Length) loop
         if Model.Diagnostics.Element (Positive (I)).From_Overload_Ranking then
            Result := Result + Model.Diagnostics.Element (Positive (I)).Mismatch_Count;
         end if;
      end loop;
      return Result;
   end Overload_Ranking_Rejection_Diagnostic_Count;

   function Fingerprint (Model : Expression_Diagnostic_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Expression_Diagnostics;
