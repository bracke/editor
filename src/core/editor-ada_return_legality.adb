with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Expected_Type_Contexts;

package body Editor.Ada_Return_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Assignment_Legality.Assignment_Context_Id;
   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Kind;
   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 17) mod 2_147_483_647;
   end Mix;

   function Bool_Slot (Value : Boolean) return Natural is
   begin
      if Value then
         return 1;
      end if;
      return 0;
   end Bool_Slot;

   function Context_Kind_Slot (Kind : Return_Context_Kind) return Natural is
   begin
      return Return_Context_Kind'Pos (Kind) + 1;
   end Context_Kind_Slot;

   function Status_Slot (Status : Return_Legality_Status) return Natural is
   begin
      return Return_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Assignment_Status_Slot
     (Status : Assignment_Legality_Status) return Natural is
   begin
      return Assignment_Legality_Status'Pos (Status) + 1;
   end Assignment_Status_Slot;

   function Context_Fingerprint (Context : Return_Context_Info) return Natural is
      H : Natural := Natural (Context.Id) + 1;
   begin
      H := Mix (H, Context_Kind_Slot (Context.Kind));
      H := Mix (H, Natural (Context.Unit_Node) + 1);
      H := Mix (H, Natural (Context.Return_Node) + 1);
      H := Mix (H, Natural (Context.Expression_Node) + 1);
      H := Mix (H, Natural (Context.Assignment_Context) + 1);
      H := Mix (H, Length (Context.Expected_Result_Subtype) + 1);
      H := Mix (H, Bool_Slot (Context.Has_Expression));
      H := Mix (H, Bool_Slot (Context.Is_Function_Context));
      H := Mix (H, Bool_Slot (Context.Is_Procedure_Context));
      H := Mix (H, Bool_Slot (Context.Is_Extended_Return));
      H := Mix (H, Bool_Slot (Context.Is_No_Return_Subprogram));
      H := Mix (H, Context.Start_Line);
      H := Mix (H, Context.Start_Column);
      H := Mix (H, Context.End_Line);
      H := Mix (H, Context.End_Column);
      H := Mix (H, Context.Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Legality_Fingerprint (Info : Return_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Context_Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Unit_Node) + 1);
      H := Mix (H, Natural (Info.Return_Node) + 1);
      H := Mix (H, Natural (Info.Expression_Node) + 1);
      H := Mix (H, Natural (Info.Assignment_Context) + 1);
      H := Mix (H, Assignment_Status_Slot (Info.Assignment_Status));
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Length (Info.Expected_Result_Subtype) + 1);
      H := Mix (H, Bool_Slot (Info.Has_Expression));
      H := Mix (H, Bool_Slot (Info.Is_Function_Context));
      H := Mix (H, Bool_Slot (Info.Is_Procedure_Context));
      H := Mix (H, Bool_Slot (Info.Is_Extended_Return));
      H := Mix (H, Bool_Slot (Info.Is_No_Return_Subprogram));
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.Start_Column);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.End_Column);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Info.Assignment_Fingerprint + 1);
      return H;
   end Legality_Fingerprint;

   function Is_Compatible_Status (Status : Return_Legality_Status) return Boolean is
   begin
      return Status in Return_Legality_Procedure_Return_Compatible |
        Return_Legality_Function_Return_Compatible |
        Return_Legality_Extended_Return_Compatible;
   end Is_Compatible_Status;

   function Is_Error_Status (Status : Return_Legality_Status) return Boolean is
   begin
      return Status in Return_Legality_Procedure_Return_With_Expression |
        Return_Legality_Function_Return_Missing_Expression |
        Return_Legality_Result_Incompatible_Subtype |
        Return_Legality_Result_Class_Wide_Incompatible |
        Return_Legality_Result_Private_View_Barrier |
        Return_Legality_Result_Limited_View_Barrier |
        Return_Legality_Result_Cross_Unit_Unresolved_View |
        Return_Legality_Result_Target_Unresolved |
        Return_Legality_Result_Source_Unresolved |
        Return_Legality_Result_Static_Range_Violation |
        Return_Legality_Result_Universal_Numeric_Unresolved |
        Return_Legality_No_Return_Subprogram_Return;
   end Is_Error_Status;

   function Is_Warning_Status (Status : Return_Legality_Status) return Boolean is
   begin
      return Status = Return_Legality_Indeterminate;
   end Is_Warning_Status;

   function Message_For (Status : Return_Legality_Status) return String is
   begin
      case Status is
         when Return_Legality_Procedure_Return_Compatible =>
            return "procedure return statement is legal";
         when Return_Legality_Function_Return_Compatible =>
            return "function return expression is compatible with the result subtype";
         when Return_Legality_Extended_Return_Compatible =>
            return "extended return object is compatible with the result subtype";
         when Return_Legality_Procedure_Return_With_Expression =>
            return "procedure return statement has an expression";
         when Return_Legality_Function_Return_Missing_Expression =>
            return "function return statement is missing an expression";
         when Return_Legality_Result_Incompatible_Subtype =>
            return "return expression subtype is incompatible with the result subtype";
         when Return_Legality_Result_Class_Wide_Incompatible =>
            return "class-wide return expression is incompatible with the result subtype";
         when Return_Legality_Result_Private_View_Barrier =>
            return "return legality is blocked by a private view";
         when Return_Legality_Result_Limited_View_Barrier =>
            return "return legality is blocked by a limited view";
         when Return_Legality_Result_Cross_Unit_Unresolved_View =>
            return "return view compatibility is unresolved across units";
         when Return_Legality_Result_Target_Unresolved =>
            return "return result subtype is unresolved";
         when Return_Legality_Result_Source_Unresolved =>
            return "return expression type is unresolved";
         when Return_Legality_Result_Static_Range_Violation =>
            return "static return expression is outside the result subtype range";
         when Return_Legality_Result_Universal_Numeric_Unresolved =>
            return "universal numeric return expression was not finally resolved";
         when Return_Legality_No_Return_Subprogram_Return =>
            return "No_Return subprogram contains a return statement";
         when Return_Legality_Indeterminate =>
            return "return statement legality is indeterminate";
         when others =>
            return "return statement legality was not checked";
      end case;
   end Message_For;

   function Detail_For (Status : Return_Legality_Status) return String is
   begin
      case Status is
         when Return_Legality_Procedure_Return_Compatible =>
            return "A procedure return statement without an expression is accepted.";
         when Return_Legality_Function_Return_Compatible =>
            return "The associated assignment-legality result accepts the expression for the function result subtype.";
         when Return_Legality_Extended_Return_Compatible =>
            return "The associated assignment-legality result accepts the extended return object initialization.";
         when Return_Legality_Procedure_Return_With_Expression =>
            return "Ada procedure return statements must not include a return expression.";
         when Return_Legality_Function_Return_Missing_Expression =>
            return "Ada function return statements must include a return expression.";
         when Return_Legality_Result_Incompatible_Subtype =>
            return "Assignment-legality metadata rejected the return expression subtype.";
         when Return_Legality_Result_Class_Wide_Incompatible =>
            return "Assignment-legality metadata rejected the class-wide return relationship.";
         when Return_Legality_Result_Private_View_Barrier =>
            return "Private-view metadata prevents accepting the return expression " &
              "until the correct view is available.";
         when Return_Legality_Result_Limited_View_Barrier =>
            return "Limited_View-view metadata exposes only an incomplete view for the result subtype or expression.";
         when Return_Legality_Result_Cross_Unit_Unresolved_View =>
            return "The required cross-unit private/limited view was missing, stale, or unresolved.";
         when Return_Legality_Result_Target_Unresolved =>
            return "No deterministic result subtype is available for this return context.";
         when Return_Legality_Result_Source_Unresolved =>
            return "No deterministic return expression type is available for this return context.";
         when Return_Legality_Result_Static_Range_Violation =>
            return "Static evaluation proves the return expression is outside the result subtype range.";
         when Return_Legality_Result_Universal_Numeric_Unresolved =>
            return "The return expression remains universal numeric without a " &
              "compatible final result subtype resolution.";
         when Return_Legality_No_Return_Subprogram_Return =>
            return "A No_Return subprogram must not complete by executing a return statement.";
         when Return_Legality_Indeterminate =>
            return "Return, expression, result subtype, and assignment-legality " &
              "metadata are insufficient for a deterministic result.";
         when others =>
            return "The context is not currently a return-legality candidate.";
      end case;
   end Detail_For;

   procedure Clear (Model : in out Return_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Model_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Return_Context_Model;
      Context : Return_Context_Info)
   is
      Item : Return_Context_Info := Context;
   begin
      if Item.Id = No_Return_Context then
         Item.Id := Return_Context_Id (Natural (Model.Items.Length) + 1);
      end if;
      if Item.Fingerprint = 0 then
         Item.Fingerprint := Context_Fingerprint (Item);
      end if;
      Model.Items.Append (Item);
      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, Item.Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Return_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Return_Context_Model;
      Index : Positive) return Return_Context_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Return_Context_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Build_Contexts_From_Expected_Types
     (Expected    : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model)
      return Return_Context_Model
   is
      package ETC renames Editor.Ada_Expected_Type_Contexts;
      package AL renames Editor.Ada_Assignment_Legality;
      Model : Return_Context_Model;
   begin
      for Index in 1 .. ETC.Expected_Context_Count (Expected) loop
         declare
            Expected_Row : constant ETC.Expected_Context_Info :=
              ETC.Expected_Context_At (Expected, Index);
            Assignment : constant AL.Assignment_Legality_Info :=
              AL.First_For_Target_Node (Assignments, Expected_Row.Context_Node);
            Context : Return_Context_Info;
         begin
            if Expected_Row.Kind = ETC.Expected_Context_Return_Statement
              and then Expected_Row.Status = ETC.Expected_Context_Found
            then
               Context.Kind := Return_Context_Function_Return;
               Context.Unit_Node := Expected_Row.Context_Node;
               Context.Return_Node := Expected_Row.Context_Node;
               Context.Expression_Node := Expected_Row.Node;
               Context.Assignment_Context := Assignment.Context;
               Context.Expected_Result_Subtype := Expected_Row.Expected_Subtype;
               Context.Has_Expression :=
                 Expected_Row.Node /= Editor.Ada_Syntax_Tree.No_Node;
               Context.Is_Function_Context := True;
               Context.Is_Procedure_Context := False;
               Context.Start_Line := Expected_Row.Start_Line;
               Context.End_Line := Expected_Row.End_Line;
               Context.Fingerprint :=
                 Mix (Expected_Row.Fingerprint, Assignment.Fingerprint + 1);
               Add_Context (Model, Context);
            end if;
         end;
      end loop;

      return Model;
   end Build_Contexts_From_Expected_Types;

   function Map_Assignment_Status
     (Context    : Return_Context_Info;
      Assignment : Editor.Ada_Assignment_Legality.Assignment_Legality_Info)
      return Return_Legality_Status is
      package AL renames Editor.Ada_Assignment_Legality;
   begin
      if not AL.Has_Legality (Assignment) then
         return Return_Legality_Indeterminate;
      end if;

      case Assignment.Status is
         when AL.Assignment_Legality_Compatible |
              AL.Assignment_Legality_Class_Wide_Compatible |
              AL.Assignment_Legality_Static_Range_Compatible =>
            if Context.Kind = Return_Context_Extended_Return
              or else Context.Is_Extended_Return
            then
               return Return_Legality_Extended_Return_Compatible;
            end if;
            return Return_Legality_Function_Return_Compatible;
         when AL.Assignment_Legality_Incompatible_Subtype =>
            return Return_Legality_Result_Incompatible_Subtype;
         when AL.Assignment_Legality_Class_Wide_Incompatible =>
            return Return_Legality_Result_Class_Wide_Incompatible;
         when AL.Assignment_Legality_Target_Unresolved =>
            return Return_Legality_Result_Target_Unresolved;
         when AL.Assignment_Legality_Source_Unresolved =>
            return Return_Legality_Result_Source_Unresolved;
         when AL.Assignment_Legality_Private_View_Barrier =>
            return Return_Legality_Result_Private_View_Barrier;
         when AL.Assignment_Legality_Limited_View_Barrier =>
            return Return_Legality_Result_Limited_View_Barrier;
         when AL.Assignment_Legality_Cross_Unit_Unresolved_View =>
            return Return_Legality_Result_Cross_Unit_Unresolved_View;
         when AL.Assignment_Legality_Static_Range_Violation =>
            return Return_Legality_Result_Static_Range_Violation;
         when AL.Assignment_Legality_Universal_Numeric_Unresolved =>
            return Return_Legality_Result_Universal_Numeric_Unresolved;
         when others =>
            return Return_Legality_Indeterminate;
      end case;
   end Map_Assignment_Status;

   function Classify
     (Context     : Return_Context_Info;
      Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model)
      return Return_Legality_Info is
      package AL renames Editor.Ada_Assignment_Legality;
      Assignment : AL.Assignment_Legality_Info := (others => <>);
      Result     : Return_Legality_Info;
   begin
      Result.Context := Context.Id;
      Result.Kind := Context.Kind;
      Result.Unit_Node := Context.Unit_Node;
      Result.Return_Node := Context.Return_Node;
      Result.Expression_Node := Context.Expression_Node;
      Result.Assignment_Context := Context.Assignment_Context;
      Result.Expected_Result_Subtype := Context.Expected_Result_Subtype;
      Result.Has_Expression := Context.Has_Expression;
      Result.Is_Function_Context := Context.Is_Function_Context;
      Result.Is_Procedure_Context := Context.Is_Procedure_Context;
      Result.Is_Extended_Return := Context.Is_Extended_Return;
      Result.Is_No_Return_Subprogram := Context.Is_No_Return_Subprogram;
      Result.Start_Line := Context.Start_Line;
      Result.Start_Column := Context.Start_Column;
      Result.End_Line := Context.End_Line;
      Result.End_Column := Context.End_Column;
      Result.Source_Fingerprint := Context.Fingerprint;

      if Context.Assignment_Context /= AL.No_Assignment_Context then
         Assignment := AL.First_For_Context (Assignments, Context.Assignment_Context);
         Result.Assignment_Status := Assignment.Status;
         Result.Assignment_Fingerprint := Assignment.Fingerprint;
      end if;

      if Context.Is_No_Return_Subprogram
        or else Context.Kind = Return_Context_No_Return_Subprogram
      then
         Result.Status := Return_Legality_No_Return_Subprogram_Return;
      elsif Context.Kind = Return_Context_Procedure_Return
        or else Context.Is_Procedure_Context
      then
         if Context.Has_Expression then
            Result.Status := Return_Legality_Procedure_Return_With_Expression;
         else
            Result.Status := Return_Legality_Procedure_Return_Compatible;
         end if;
      elsif Context.Kind = Return_Context_Function_Return
        or else Context.Is_Function_Context
        or else Context.Kind = Return_Context_Extended_Return
        or else Context.Is_Extended_Return
      then
         if not Context.Has_Expression
           and then not (Context.Kind = Return_Context_Extended_Return
                         or else Context.Is_Extended_Return)
         then
            Result.Status := Return_Legality_Function_Return_Missing_Expression;
         else
            Result.Status := Map_Assignment_Status (Context, Assignment);
         end if;
      else
         Result.Status := Return_Legality_Indeterminate;
      end if;

      Result.Message := To_Unbounded_String (Message_For (Result.Status));
      Result.Detail := To_Unbounded_String (Detail_For (Result.Status));
      return Result;
   end Classify;

   procedure Accumulate
     (Model : in out Return_Legality_Model;
      Info  : Return_Legality_Info) is
   begin
      if Is_Compatible_Status (Info.Status) then
         Model.Compatible_Total := Model.Compatible_Total + 1;
      elsif Is_Error_Status (Info.Status) then
         Model.Error_Total := Model.Error_Total + 1;
      elsif Is_Warning_Status (Info.Status) then
         Model.Warning_Total := Model.Warning_Total + 1;
      end if;

      case Info.Status is
         when Return_Legality_Procedure_Return_With_Expression =>
            Model.Procedure_With_Expression_Total :=
              Model.Procedure_With_Expression_Total + 1;
         when Return_Legality_Function_Return_Missing_Expression =>
            Model.Function_Missing_Expression_Total :=
              Model.Function_Missing_Expression_Total + 1;
         when Return_Legality_No_Return_Subprogram_Return =>
            Model.No_Return_Subprogram_Return_Total :=
              Model.No_Return_Subprogram_Return_Total + 1;
         when Return_Legality_Result_Incompatible_Subtype |
              Return_Legality_Result_Class_Wide_Incompatible =>
            Model.Incompatible_Result_Total := Model.Incompatible_Result_Total + 1;
         when Return_Legality_Result_Private_View_Barrier =>
            Model.Private_View_Barrier_Total := Model.Private_View_Barrier_Total + 1;
         when Return_Legality_Result_Limited_View_Barrier =>
            Model.Limited_View_Barrier_Total := Model.Limited_View_Barrier_Total + 1;
         when Return_Legality_Result_Static_Range_Violation =>
            Model.Static_Range_Violation_Total :=
              Model.Static_Range_Violation_Total + 1;
         when Return_Legality_Result_Universal_Numeric_Unresolved =>
            Model.Universal_Numeric_Unresolved_Total :=
              Model.Universal_Numeric_Unresolved_Total + 1;
         when others =>
            null;
      end case;
   end Accumulate;

   function Build
     (Contexts    : Return_Context_Model;
      Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model)
      return Return_Legality_Model is
      Model : Return_Legality_Model;
   begin
      for Index in 1 .. Natural (Contexts.Items.Length) loop
         declare
            Info : Return_Legality_Info :=
              Classify (Contexts.Items.Element (Index), Assignments);
         begin
            Info.Id := Return_Legality_Id (Natural (Model.Items.Length) + 1);
            Info.Fingerprint := Legality_Fingerprint (Info);
            Model.Items.Append (Info);
            Accumulate (Model, Info);
            Model.Model_Fingerprint := Mix (Model.Model_Fingerprint,
                                             Info.Fingerprint + 1);
         end;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Return_Legality_Model;
      Index : Positive) return Return_Legality_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Context
     (Model   : Return_Legality_Model;
      Context : Return_Context_Id) return Return_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Context = Context then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Context;

   function First_For_Return_Node
     (Model : Return_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Return_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Return_Node = Node
           and then Node /= Editor.Ada_Syntax_Tree.No_Node
         then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Return_Node;

   function First_For_Assignment_Context
     (Model   : Return_Legality_Model;
      Context : Assignment_Context_Id) return Return_Legality_Info is
   begin
      for Item of Model.Items loop
         if Item.Assignment_Context = Context
           and then Context /= Editor.Ada_Assignment_Legality.No_Assignment_Context
         then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Assignment_Context;

   function Results_For_Status
     (Model  : Return_Legality_Model;
      Status : Return_Legality_Status) return Return_Legality_Result_Set is
      Results : Return_Legality_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Results_For_Status;

   function Result_Count (Results : Return_Legality_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Return_Legality_Result_Set;
      Index   : Positive) return Return_Legality_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Return_Legality_Model;
      Status : Return_Legality_Status) return Natural is
      Total : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Status;

   function Compatible_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Compatible_Total;
   end Compatible_Count;

   function Error_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Procedure_With_Expression_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Procedure_With_Expression_Total;
   end Procedure_With_Expression_Count;

   function Function_Missing_Expression_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Function_Missing_Expression_Total;
   end Function_Missing_Expression_Count;

   function No_Return_Subprogram_Return_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.No_Return_Subprogram_Return_Total;
   end No_Return_Subprogram_Return_Count;

   function Incompatible_Result_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Incompatible_Result_Total;
   end Incompatible_Result_Count;

   function Private_View_Barrier_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Private_View_Barrier_Total;
   end Private_View_Barrier_Count;

   function Limited_View_Barrier_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Limited_View_Barrier_Total;
   end Limited_View_Barrier_Count;

   function Static_Range_Violation_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Static_Range_Violation_Total;
   end Static_Range_Violation_Count;

   function Universal_Numeric_Unresolved_Count (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Universal_Numeric_Unresolved_Total;
   end Universal_Numeric_Unresolved_Count;

   function Has_Legality (Info : Return_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Return_Legality
        and then Info.Context /= No_Return_Context
        and then Info.Status /= Return_Legality_Not_Checked;
   end Has_Legality;

   function Fingerprint (Model : Return_Legality_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Return_Legality;
