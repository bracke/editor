with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Dispatching_Call_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Expression_Types.Expression_Type_Id;
   use type Editor.Ada_Expression_Types.Dispatching_Call_Inference_Status;
   use type Dispatching_Legality_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 251) + B + 197) mod 1_000_000_007;
   end Mix;

   function Status_Slot (Status : Dispatching_Legality_Status) return Natural is
   begin
      return Dispatching_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Source_Status_Slot
     (Status : Editor.Ada_Expression_Types.Dispatching_Call_Inference_Status)
      return Natural is
   begin
      return Editor.Ada_Expression_Types.Dispatching_Call_Inference_Status'Pos (Status) + 1;
   end Source_Status_Slot;

   function Is_Resolved_Status (Status : Dispatching_Legality_Status) return Boolean is
   begin
      return Status in Dispatching_Legality_Static_Binding |
        Dispatching_Legality_Dynamic_Dispatch |
        Dispatching_Legality_Controlling_Result |
        Dispatching_Legality_Primitive_Target;
   end Is_Resolved_Status;

   function Is_Error_Status (Status : Dispatching_Legality_Status) return Boolean is
   begin
      return Status in Dispatching_Legality_Target_Unresolved |
        Dispatching_Legality_Target_Ambiguous |
        Dispatching_Legality_Controlling_Unknown |
        Dispatching_Legality_Abstract_Unknown;
   end Is_Error_Status;

   function Is_Warning_Status (Status : Dispatching_Legality_Status) return Boolean is
   begin
      return Status = Dispatching_Legality_Indeterminate;
   end Is_Warning_Status;

   function Legality_Fingerprint (Info : Dispatching_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Expression) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Source_Status_Slot (Info.Source_Status));
      H := Mix (H, Info.Primitive_Count + 1);
      H := Mix (H, Info.Controlling_Operand_Count + 1);
      H := Mix (H, Info.Controlling_Result_Count + 1);
      H := Mix (H, Info.Ambiguous_Count + 1);
      H := Mix (H, Info.Unknown_Count + 1);
      H := Mix (H, Length (Info.Normalized_Controlling_Subtype) + 1);
      H := Mix (H, Length (Info.Normalized_Result_Subtype) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Legality_Fingerprint;

   function Status_For
     (Info : Expression_Info) return Dispatching_Legality_Status is
   begin
      case Info.Dispatching_Call_Status is
         when Editor.Ada_Expression_Types.Dispatching_Call_Not_Checked =>
            return Dispatching_Legality_Not_Checked;
         when Editor.Ada_Expression_Types.Dispatching_Call_Not_Call =>
            return Dispatching_Legality_Not_Dispatching_Call;
         when Editor.Ada_Expression_Types.Dispatching_Call_Primitive_Target =>
            return Dispatching_Legality_Primitive_Target;
         when Editor.Ada_Expression_Types.Dispatching_Call_Class_Wide_Controlling_Operand =>
            return Dispatching_Legality_Dynamic_Dispatch;
         when Editor.Ada_Expression_Types.Dispatching_Call_Controlling_Result =>
            return Dispatching_Legality_Controlling_Result;
         when Editor.Ada_Expression_Types.Dispatching_Call_Static_Binding =>
            return Dispatching_Legality_Static_Binding;
         when Editor.Ada_Expression_Types.Dispatching_Call_Dynamic_Dispatch =>
            return Dispatching_Legality_Dynamic_Dispatch;
         when Editor.Ada_Expression_Types.Dispatching_Call_Target_Unresolved =>
            return Dispatching_Legality_Target_Unresolved;
         when Editor.Ada_Expression_Types.Dispatching_Call_Target_Ambiguous =>
            return Dispatching_Legality_Target_Ambiguous;
         when Editor.Ada_Expression_Types.Dispatching_Call_Controlling_Unknown =>
            return Dispatching_Legality_Controlling_Unknown;
      end case;
   end Status_For;

   function Message_For (Status : Dispatching_Legality_Status) return String is
   begin
      case Status is
         when Dispatching_Legality_Static_Binding =>
            return "dispatching call is statically bound";
         when Dispatching_Legality_Dynamic_Dispatch =>
            return "dispatching call has a controlling operand";
         when Dispatching_Legality_Controlling_Result =>
            return "dispatching call depends on a controlling result";
         when Dispatching_Legality_Primitive_Target =>
            return "dispatching call targets a primitive operation";
         when Dispatching_Legality_Target_Unresolved =>
            return "dispatching call target is unresolved";
         when Dispatching_Legality_Target_Ambiguous =>
            return "dispatching call target is ambiguous";
         when Dispatching_Legality_Controlling_Unknown =>
            return "dispatching controlling operand or result is unknown";
         when Dispatching_Legality_Abstract_Unknown =>
            return "dispatching call abstractness is unknown";
         when Dispatching_Legality_Indeterminate =>
            return "dispatching call legality is indeterminate";
         when others =>
            return "not a dispatching-call legality target";
      end case;
   end Message_For;

   function Detail_For (Status : Dispatching_Legality_Status) return String is
   begin
      case Status is
         when Dispatching_Legality_Static_Binding =>
            return "The selected primitive call has no class-wide controlling operand requiring dynamic dispatch.";
         when Dispatching_Legality_Dynamic_Dispatch =>
            return "A class-wide controlling operand makes the primitive call dynamically dispatched.";
         when Dispatching_Legality_Controlling_Result =>
            return "The primitive call carries controlling-result metadata that must be checked by later target-name/context rules.";
         when Dispatching_Legality_Primitive_Target =>
            return "The callable target is recognized as a primitive operation with controlling metadata.";
         when Dispatching_Legality_Target_Unresolved =>
            return "The callable target could not be resolved, so dispatching legality cannot be completed.";
         when Dispatching_Legality_Target_Ambiguous =>
            return "Multiple callable targets remain, so dispatching legality cannot choose a unique primitive.";
         when Dispatching_Legality_Controlling_Unknown =>
            return "The controlling operand/result subtype metadata is unavailable or incomplete.";
         when Dispatching_Legality_Abstract_Unknown =>
            return "Abstract primitive metadata is unavailable for this call target.";
         when Dispatching_Legality_Indeterminate =>
            return "The dispatching-call inference status is not enough to classify legality deterministically.";
         when others =>
            return "The expression is not currently classified as a dispatching-call legality candidate.";
      end case;
   end Detail_For;

   function Make_Info
     (Expr : Expression_Info;
      Id   : Dispatching_Legality_Id) return Dispatching_Legality_Info is
      Result : Dispatching_Legality_Info;
   begin
      Result.Id := Id;
      Result.Expression := Expr.Id;
      Result.Node := Expr.Node;
      Result.Status := Status_For (Expr);
      Result.Source_Status := Expr.Dispatching_Call_Status;
      Result.Message := To_Unbounded_String (Message_For (Result.Status));
      Result.Detail := To_Unbounded_String (Detail_For (Result.Status));
      Result.Controlling_Subtype := Expr.Dispatching_Call_Controlling_Subtype;
      Result.Normalized_Controlling_Subtype :=
        Expr.Normalized_Dispatching_Call_Controlling_Subtype;
      Result.Result_Subtype := Expr.Dispatching_Call_Result_Subtype;
      Result.Normalized_Result_Subtype :=
        Expr.Normalized_Dispatching_Call_Result_Subtype;
      Result.Primitive_Count := Expr.Dispatching_Call_Primitive_Count;
      Result.Controlling_Operand_Count := Expr.Dispatching_Call_Controlling_Operand_Count;
      Result.Controlling_Result_Count := Expr.Dispatching_Call_Controlling_Result_Count;
      Result.Ambiguous_Count := Expr.Dispatching_Call_Ambiguous_Count;
      Result.Unknown_Count := Expr.Dispatching_Call_Unknown_Count;
      Result.Start_Line := Expr.Start_Line;
      Result.End_Line := Expr.End_Line;
      Result.Source_Fingerprint := Expr.Fingerprint;
      Result.Fingerprint := Legality_Fingerprint (Result);
      return Result;
   end Make_Info;

   procedure Append (Model : in out Dispatching_Legality_Model; Info : Dispatching_Legality_Info) is
   begin
      if not Has_Legality (Info) then
         return;
      end if;

      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint + 1);

      if Is_Resolved_Status (Info.Status) then
         Model.Resolved_Total := Model.Resolved_Total + 1;
      end if;
      if Info.Status = Dispatching_Legality_Dynamic_Dispatch then
         Model.Dynamic_Total := Model.Dynamic_Total + 1;
      elsif Info.Status = Dispatching_Legality_Static_Binding then
         Model.Static_Total := Model.Static_Total + 1;
      elsif Info.Status = Dispatching_Legality_Controlling_Result then
         Model.Controlling_Result_Total := Model.Controlling_Result_Total + 1;
      elsif Info.Status = Dispatching_Legality_Primitive_Target then
         Model.Primitive_Target_Total := Model.Primitive_Target_Total + 1;
      elsif Info.Status = Dispatching_Legality_Target_Ambiguous then
         Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
      elsif Info.Status = Dispatching_Legality_Target_Unresolved then
         Model.Unresolved_Total := Model.Unresolved_Total + 1;
      elsif Info.Status = Dispatching_Legality_Controlling_Unknown then
         Model.Unknown_Total := Model.Unknown_Total + 1;
      end if;

      if Is_Error_Status (Info.Status) then
         Model.Error_Total := Model.Error_Total + 1;
      elsif Is_Warning_Status (Info.Status) then
         Model.Warning_Total := Model.Warning_Total + 1;
      else
         Model.Info_Total := Model.Info_Total + 1;
      end if;
   end Append;

   procedure Clear (Model : in out Dispatching_Legality_Model) is
   begin
      Model.Items.Clear;
      Model.Resolved_Total := 0;
      Model.Dynamic_Total := 0;
      Model.Static_Total := 0;
      Model.Controlling_Result_Total := 0;
      Model.Primitive_Target_Total := 0;
      Model.Ambiguous_Total := 0;
      Model.Unresolved_Total := 0;
      Model.Unknown_Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return Dispatching_Legality_Model is
      Model : Dispatching_Legality_Model;
   begin
      Model.Result_Fingerprint := Editor.Ada_Expression_Types.Fingerprint (Expressions);
      for Index in 1 .. Editor.Ada_Expression_Types.Expression_Type_Count (Expressions) loop
         declare
            Expr : constant Expression_Info :=
              Editor.Ada_Expression_Types.Expression_Type_At (Expressions, Index);
         begin
            Append (Model, Make_Info
              (Expr, Dispatching_Legality_Id (Natural (Model.Items.Length) + 1)));
         end;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Dispatching_Legality_Model;
      Index : Positive) return Dispatching_Legality_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Expression
     (Model      : Dispatching_Legality_Model;
      Expression : Editor.Ada_Expression_Types.Expression_Type_Id)
      return Dispatching_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Expression = Expression then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Expression;

   function First_For_Node
     (Model : Dispatching_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Dispatching_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Node = Node then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Results_For_Node
     (Model : Dispatching_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Dispatching_Legality_Result_Set is
      Results : Dispatching_Legality_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Node = Node then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Results_For_Node;

   function Result_Count (Results : Dispatching_Legality_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Dispatching_Legality_Result_Set;
      Index   : Positive) return Dispatching_Legality_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Dispatching_Legality_Model;
      Status : Dispatching_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Resolved_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Resolved_Total;
   end Resolved_Count;

   function Dynamic_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Dynamic_Total;
   end Dynamic_Count;

   function Static_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Static_Total;
   end Static_Count;

   function Controlling_Result_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Controlling_Result_Total;
   end Controlling_Result_Count;

   function Primitive_Target_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Primitive_Target_Total;
   end Primitive_Target_Count;

   function Ambiguous_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Count;

   function Unresolved_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Unresolved_Total;
   end Unresolved_Count;

   function Unknown_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Count;

   function Error_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Has_Legality (Info : Dispatching_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Dispatching_Legality
        and then Info.Status not in Dispatching_Legality_Not_Checked |
          Dispatching_Legality_Not_Dispatching_Call;
   end Has_Legality;

   function Fingerprint (Model : Dispatching_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Dispatching_Call_Legality;
