with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Control_Flow_Legality is

   use type Editor.Ada_Return_Legality.Return_Legality_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 283) + B + 239) mod 1_000_000_007;
   end Mix;

   function Bool_Slot (Value : Boolean) return Natural is
   begin
      if Value then
         return 2;
      else
         return 1;
      end if;
   end Bool_Slot;

   function Kind_Slot (Kind : Flow_Context_Kind) return Natural is
   begin
      return Flow_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Flow_Legality_Status) return Natural is
   begin
      return Flow_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Context_Fingerprint (Context : Flow_Context_Info) return Natural is
      H : Natural := Natural (Context.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Context.Kind));
      H := Mix (H, Natural (Context.Node) + 1);
      H := Mix (H, Natural (Context.Target_Node) + 1);
      H := Mix (H, Natural (Context.Condition_Node) + 1);
      H := Mix (H, Length (Context.Normalized_Condition_Subtype) + 1);
      H := Mix (H, Length (Context.Normalized_Case_Subtype) + 1);
      H := Mix (H, Length (Context.Normalized_Target_Name) + 1);
      H := Mix (H, Bool_Slot (Context.Condition_Type_Resolved));
      H := Mix (H, Bool_Slot (Context.Condition_Is_Boolean));
      H := Mix (H, Bool_Slot (Context.Case_Expression_Resolved));
      H := Mix (H, Bool_Slot (Context.Case_Choices_Static));
      H := Mix (H, Bool_Slot (Context.Case_Choices_Complete));
      H := Mix (H, Bool_Slot (Context.Case_Has_Duplicate_Choice));
      H := Mix (H, Bool_Slot (Context.Case_Choice_Type_Mismatch));
      H := Mix (H, Bool_Slot (Context.Exit_Has_Target));
      H := Mix (H, Bool_Slot (Context.Exit_Target_Resolved));
      H := Mix (H, Bool_Slot (Context.Exit_Target_Is_Loop));
      H := Mix (H, Bool_Slot (Context.Exit_Is_Inside_Loop));
      H := Mix (H, Bool_Slot (Context.Goto_Target_Resolved));
      H := Mix (H, Bool_Slot (Context.Goto_Into_Deeper_Scope));
      H := Mix (H, Bool_Slot (Context.Goto_Out_Of_Handler));
      H := Mix (H, Bool_Slot (Context.Label_Is_Duplicate));
      H := Mix (H, Bool_Slot (Context.Exception_Choice_Resolved));
      H := Mix (H, Bool_Slot (Context.Exception_Choice_Duplicate));
      H := Mix (H, Bool_Slot (Context.Exception_Others_Is_Last));
      H := Mix (H, Bool_Slot (Context.Raise_Exception_Resolved));
      H := Mix (H, Bool_Slot (Context.Select_Has_Illegal_Alternative));
      H := Mix (H, Bool_Slot (Context.Accept_Entry_Resolved));
      H := Mix (H, Bool_Slot (Context.Requeue_Target_Resolved));
      H := Mix (H, Bool_Slot (Context.Subprogram_Requires_Return));
      H := Mix (H, Bool_Slot (Context.Subprogram_Has_Complete_Return_Path));
      H := Mix (H, Natural (Context.Return_Legality) + 1);
      H := Mix (H, Context.Start_Line);
      H := Mix (H, Context.Start_Column);
      H := Mix (H, Context.End_Line);
      H := Mix (H, Context.End_Column);
      return H;
   end Context_Fingerprint;

   function Result_Fingerprint (Info : Flow_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Natural (Info.Condition_Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Length (Info.Normalized_Condition_Subtype) + 1);
      H := Mix (H, Length (Info.Normalized_Case_Subtype) + 1);
      H := Mix (H, Length (Info.Normalized_Target_Name) + 1);
      H := Mix (H, Natural (Info.Return_Legality) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.Start_Column);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.End_Column);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Result_Fingerprint;

   function Is_Compatible (Status : Flow_Legality_Status) return Boolean is
   begin
      return Status in Flow_Legality_Legal_Boolean_Condition |
        Flow_Legality_Legal_Case_Statement |
        Flow_Legality_Legal_Exit |
        Flow_Legality_Legal_Goto |
        Flow_Legality_Legal_Label |
        Flow_Legality_Legal_Exception_Handler |
        Flow_Legality_Legal_Raise |
        Flow_Legality_Legal_Select |
        Flow_Legality_Legal_Accept |
        Flow_Legality_Legal_Requeue |
        Flow_Legality_Legal_Return_Path;
   end Is_Compatible;

   function Is_Warning (Status : Flow_Legality_Status) return Boolean is
   begin
      return Status in Flow_Legality_No_Return_Path_Indeterminate |
        Flow_Legality_Indeterminate;
   end Is_Warning;

   function Is_Error (Status : Flow_Legality_Status) return Boolean is
   begin
      return not Is_Compatible (Status)
        and then not Is_Warning (Status)
        and then Status /= Flow_Legality_Not_Checked;
   end Is_Error;

   function Message_For (Status : Flow_Legality_Status) return String is
   begin
      case Status is
         when Flow_Legality_Legal_Boolean_Condition => return "condition is Boolean";
         when Flow_Legality_Legal_Case_Statement => return "case statement is legal";
         when Flow_Legality_Legal_Exit => return "exit statement target is legal";
         when Flow_Legality_Legal_Goto => return "goto target is legal";
         when Flow_Legality_Legal_Label => return "label is legal";
         when Flow_Legality_Legal_Exception_Handler => return "exception handler choices are legal";
         when Flow_Legality_Legal_Raise => return "raise statement target is legal";
         when Flow_Legality_Legal_Select => return "select statement alternatives are legal";
         when Flow_Legality_Legal_Accept => return "accept statement entry is legal";
         when Flow_Legality_Legal_Requeue => return "requeue target is legal";
         when Flow_Legality_Legal_Return_Path => return "return path is complete";
         when Flow_Legality_Condition_Unresolved => return "condition type is unresolved";
         when Flow_Legality_Condition_Not_Boolean => return "condition is not Boolean";
         when Flow_Legality_Case_Expression_Unresolved => return "case expression type is unresolved";
         when Flow_Legality_Case_Choice_Non_Static => return "case choice is not static";
         when Flow_Legality_Case_Choice_Duplicate => return "case choice is duplicated";
         when Flow_Legality_Case_Choice_Missing => return "case statement is missing choices";
         when Flow_Legality_Case_Choice_Type_Mismatch => return "case choice type does not match expression";
         when Flow_Legality_Exit_Target_Missing => return "exit target is missing";
         when Flow_Legality_Exit_Target_Not_Loop => return "exit target is not a loop";
         when Flow_Legality_Exit_From_Non_Loop => return "exit statement is outside a loop";
         when Flow_Legality_Goto_Target_Missing => return "goto target is missing";
         when Flow_Legality_Goto_Into_Deeper_Scope => return "goto enters a deeper scope";
         when Flow_Legality_Goto_Out_Of_Handler => return "goto leaves an exception handler illegally";
         when Flow_Legality_Duplicate_Label => return "label is duplicated";
         when Flow_Legality_Exception_Choice_Unresolved => return "exception choice is unresolved";
         when Flow_Legality_Exception_Choice_Duplicate => return "exception choice is duplicated";
         when Flow_Legality_Exception_Choice_Others_Not_Last => return "others exception choice is not last";
         when Flow_Legality_Raise_Exception_Unresolved => return "raise statement exception is unresolved";
         when Flow_Legality_Select_Alternative_Error => return "select statement has an illegal alternative";
         when Flow_Legality_Accept_Entry_Missing => return "accept statement entry is missing";
         when Flow_Legality_Requeue_Target_Unresolved => return "requeue target is unresolved";
         when Flow_Legality_Missing_Return_Path => return "function body is missing a complete return path";
         when Flow_Legality_Return_Path_Contains_Illegal_Return => return "return path contains an illegal return";
         when Flow_Legality_No_Return_Path_Indeterminate => return "return path completeness is indeterminate";
         when Flow_Legality_Indeterminate => return "control-flow legality is indeterminate";
         when Flow_Legality_Not_Checked => return "control-flow legality was not checked";
      end case;
   end Message_For;

   function Detail_For (Context : Flow_Context_Info; Status : Flow_Legality_Status)
      return String is
   begin
      case Status is
         when Flow_Legality_Condition_Not_Boolean |
              Flow_Legality_Condition_Unresolved =>
            return "condition subtype=" & To_String (Context.Normalized_Condition_Subtype);
         when Flow_Legality_Goto_Target_Missing |
              Flow_Legality_Exit_Target_Missing |
              Flow_Legality_Requeue_Target_Unresolved =>
            return "target=" & To_String (Context.Normalized_Target_Name);
         when Flow_Legality_Case_Expression_Unresolved |
              Flow_Legality_Case_Choice_Type_Mismatch =>
            return "case subtype=" & To_String (Context.Normalized_Case_Subtype);
         when others =>
            return "context=" & Flow_Context_Kind'Image (Context.Kind);
      end case;
   end Detail_For;

   function Return_Is_Error
     (Returns : Editor.Ada_Return_Legality.Return_Legality_Model;
      Id      : Editor.Ada_Return_Legality.Return_Legality_Id) return Boolean
   is
   begin
      if Id = Editor.Ada_Return_Legality.No_Return_Legality then
         return False;
      end if;

      for Index in 1 .. Editor.Ada_Return_Legality.Legality_Count (Returns) loop
         declare
            Row : constant Editor.Ada_Return_Legality.Return_Legality_Info :=
              Editor.Ada_Return_Legality.Legality_At (Returns, Index);
         begin
            if Row.Id = Id then
               return Row.Status not in
                 Editor.Ada_Return_Legality.Return_Legality_Procedure_Return_Compatible |
                 Editor.Ada_Return_Legality.Return_Legality_Function_Return_Compatible |
                 Editor.Ada_Return_Legality.Return_Legality_Extended_Return_Compatible;
            end if;
         end;
      end loop;

      return False;
   end Return_Is_Error;

   function Classify
     (Context : Flow_Context_Info;
      Returns : Editor.Ada_Return_Legality.Return_Legality_Model)
      return Flow_Legality_Status is
   begin
      case Context.Kind is
         when Flow_Context_If_Statement |
              Flow_Context_Elsif_Condition |
              Flow_Context_While_Loop =>
            if not Context.Condition_Type_Resolved then
               return Flow_Legality_Condition_Unresolved;
            elsif not Context.Condition_Is_Boolean then
               return Flow_Legality_Condition_Not_Boolean;
            else
               return Flow_Legality_Legal_Boolean_Condition;
            end if;

         when Flow_Context_Case_Statement =>
            if not Context.Case_Expression_Resolved then
               return Flow_Legality_Case_Expression_Unresolved;
            elsif not Context.Case_Choices_Static then
               return Flow_Legality_Case_Choice_Non_Static;
            elsif Context.Case_Has_Duplicate_Choice then
               return Flow_Legality_Case_Choice_Duplicate;
            elsif not Context.Case_Choices_Complete then
               return Flow_Legality_Case_Choice_Missing;
            elsif Context.Case_Choice_Type_Mismatch then
               return Flow_Legality_Case_Choice_Type_Mismatch;
            else
               return Flow_Legality_Legal_Case_Statement;
            end if;

         when Flow_Context_Exit_Statement =>
            if not Context.Exit_Is_Inside_Loop then
               return Flow_Legality_Exit_From_Non_Loop;
            elsif Context.Exit_Has_Target and then not Context.Exit_Target_Resolved then
               return Flow_Legality_Exit_Target_Missing;
            elsif Context.Exit_Has_Target and then not Context.Exit_Target_Is_Loop then
               return Flow_Legality_Exit_Target_Not_Loop;
            else
               return Flow_Legality_Legal_Exit;
            end if;

         when Flow_Context_Goto_Statement =>
            if not Context.Goto_Target_Resolved then
               return Flow_Legality_Goto_Target_Missing;
            elsif Context.Goto_Into_Deeper_Scope then
               return Flow_Legality_Goto_Into_Deeper_Scope;
            elsif Context.Goto_Out_Of_Handler then
               return Flow_Legality_Goto_Out_Of_Handler;
            else
               return Flow_Legality_Legal_Goto;
            end if;

         when Flow_Context_Label =>
            if Context.Label_Is_Duplicate then
               return Flow_Legality_Duplicate_Label;
            else
               return Flow_Legality_Legal_Label;
            end if;

         when Flow_Context_Exception_Handler =>
            if not Context.Exception_Choice_Resolved then
               return Flow_Legality_Exception_Choice_Unresolved;
            elsif Context.Exception_Choice_Duplicate then
               return Flow_Legality_Exception_Choice_Duplicate;
            elsif not Context.Exception_Others_Is_Last then
               return Flow_Legality_Exception_Choice_Others_Not_Last;
            else
               return Flow_Legality_Legal_Exception_Handler;
            end if;

         when Flow_Context_Raise_Statement =>
            if not Context.Raise_Exception_Resolved then
               return Flow_Legality_Raise_Exception_Unresolved;
            else
               return Flow_Legality_Legal_Raise;
            end if;

         when Flow_Context_Select_Statement =>
            if Context.Select_Has_Illegal_Alternative then
               return Flow_Legality_Select_Alternative_Error;
            else
               return Flow_Legality_Legal_Select;
            end if;

         when Flow_Context_Accept_Statement =>
            if not Context.Accept_Entry_Resolved then
               return Flow_Legality_Accept_Entry_Missing;
            else
               return Flow_Legality_Legal_Accept;
            end if;

         when Flow_Context_Requeue_Statement =>
            if not Context.Requeue_Target_Resolved then
               return Flow_Legality_Requeue_Target_Unresolved;
            else
               return Flow_Legality_Legal_Requeue;
            end if;

         when Flow_Context_Subprogram_Body =>
            if Return_Is_Error (Returns, Context.Return_Legality) then
               return Flow_Legality_Return_Path_Contains_Illegal_Return;
            elsif Context.Subprogram_Requires_Return
              and then not Context.Subprogram_Has_Complete_Return_Path
            then
               return Flow_Legality_Missing_Return_Path;
            elsif Context.Subprogram_Requires_Return then
               return Flow_Legality_Legal_Return_Path;
            else
               return Flow_Legality_Legal_Return_Path;
            end if;

         when Flow_Context_Block =>
            return Flow_Legality_Legal_Return_Path;

         when Flow_Context_Unknown =>
            return Flow_Legality_Indeterminate;
      end case;
   end Classify;

   function Make_Result
     (Context : Flow_Context_Info;
      Id      : Flow_Legality_Id;
      Status  : Flow_Legality_Status) return Flow_Legality_Info is
      Row : Flow_Legality_Info;
   begin
      Row.Id := Id;
      Row.Context := Context.Id;
      Row.Kind := Context.Kind;
      Row.Node := Context.Node;
      Row.Target_Node := Context.Target_Node;
      Row.Condition_Node := Context.Condition_Node;
      Row.Status := Status;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String (Detail_For (Context, Status));
      Row.Normalized_Condition_Subtype := Context.Normalized_Condition_Subtype;
      Row.Normalized_Case_Subtype := Context.Normalized_Case_Subtype;
      Row.Normalized_Target_Name := Context.Normalized_Target_Name;
      Row.Return_Legality := Context.Return_Legality;
      Row.Start_Line := Context.Start_Line;
      Row.Start_Column := Context.Start_Column;
      Row.End_Line := Context.End_Line;
      Row.End_Column := Context.End_Column;
      Row.Source_Fingerprint := Context_Fingerprint (Context);
      Row.Fingerprint := Result_Fingerprint (Row);
      return Row;
   end Make_Result;

   procedure Clear (Model : in out Flow_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Flow_Context_Model;
      Context : Flow_Context_Info) is
      Copy : Flow_Context_Info := Context;
   begin
      if Length (Copy.Normalized_Condition_Subtype) = 0 then
         Copy.Normalized_Condition_Subtype := Copy.Condition_Subtype;
      end if;
      if Length (Copy.Normalized_Case_Subtype) = 0 then
         Copy.Normalized_Case_Subtype := Copy.Case_Expression_Subtype;
      end if;
      if Length (Copy.Normalized_Target_Name) = 0 then
         Copy.Normalized_Target_Name := Copy.Target_Name;
      end if;
      Copy.Fingerprint := Context_Fingerprint (Copy);
      Model.Contexts.Append (Copy);
      Model.Fingerprint := Mix (Model.Fingerprint, Copy.Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Flow_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Flow_Context_Model;
      Index : Positive) return Flow_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Flow_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Flow_Context_Model;
      Returns  : Editor.Ada_Return_Legality.Return_Legality_Model)
      return Flow_Legality_Model is
      Model : Flow_Legality_Model;
      Next  : Natural := 1;
   begin
      for Index in 1 .. Context_Count (Contexts) loop
         declare
            Context : constant Flow_Context_Info := Context_At (Contexts, Index);
            Status  : constant Flow_Legality_Status := Classify (Context, Returns);
            Row     : constant Flow_Legality_Info :=
              Make_Result (Context, Flow_Legality_Id (Next), Status);
         begin
            Model.Results.Append (Row);
            Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint + 1);
            Next := Next + 1;
         end;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Flow_Legality_Model) return Natural is
   begin
      return Natural (Model.Results.Length);
   end Legality_Count;

   function Legality_At
     (Model : Flow_Legality_Model;
      Index : Positive) return Flow_Legality_Info is
   begin
      return Model.Results.Element (Index);
   end Legality_At;

   function First_For_Context
     (Model   : Flow_Legality_Model;
      Context : Flow_Context_Id) return Flow_Legality_Info is
   begin
      for Row of Model.Results loop
         if Row.Context = Context then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Context;

   function First_For_Node
     (Model : Flow_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Flow_Legality_Info is
   begin
      for Row of Model.Results loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Results_For_Status
     (Model  : Flow_Legality_Model;
      Status : Flow_Legality_Status) return Flow_Legality_Result_Set is
      Results : Flow_Legality_Result_Set;
   begin
      for Row of Model.Results loop
         if Row.Status = Status then
            Results.Results.Append (Row);
         end if;
      end loop;
      return Results;
   end Results_For_Status;

   function Rows_For_Kind
     (Model : Flow_Legality_Model;
      Kind  : Flow_Context_Kind) return Flow_Legality_Result_Set is
      Results : Flow_Legality_Result_Set;
   begin
      for Row of Model.Results loop
         if Row.Kind = Kind then
            Results.Results.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Target
     (Model  : Flow_Legality_Model;
      Target : Ada.Strings.Unbounded.Unbounded_String) return Flow_Legality_Result_Set is
      Results : Flow_Legality_Result_Set;
   begin
      for Row of Model.Results loop
         if Row.Normalized_Target_Name = Target then
            Results.Results.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Target;

   function Result_Count (Results : Flow_Legality_Result_Set) return Natural is
   begin
      return Natural (Results.Results.Length);
   end Result_Count;

   function Result_At
     (Results : Flow_Legality_Result_Set;
      Index   : Positive) return Flow_Legality_Info is
   begin
      return Results.Results.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Flow_Legality_Model;
      Status : Flow_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Results loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Flow_Legality_Model;
      Kind  : Flow_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Results loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Compatible_Count (Model : Flow_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Results loop
         if Is_Compatible (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Compatible_Count;

   function Error_Count (Model : Flow_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Results loop
         if Is_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Warning_Count (Model : Flow_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Results loop
         if Is_Warning (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Warning_Count;

   function Boolean_Context_Error_Count (Model : Flow_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Flow_Legality_Condition_Unresolved) +
        Count_Status (Model, Flow_Legality_Condition_Not_Boolean);
   end Boolean_Context_Error_Count;

   function Case_Error_Count (Model : Flow_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Flow_Legality_Case_Expression_Unresolved) +
        Count_Status (Model, Flow_Legality_Case_Choice_Non_Static) +
        Count_Status (Model, Flow_Legality_Case_Choice_Duplicate) +
        Count_Status (Model, Flow_Legality_Case_Choice_Missing) +
        Count_Status (Model, Flow_Legality_Case_Choice_Type_Mismatch);
   end Case_Error_Count;

   function Exit_Goto_Error_Count (Model : Flow_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Flow_Legality_Exit_Target_Missing) +
        Count_Status (Model, Flow_Legality_Exit_Target_Not_Loop) +
        Count_Status (Model, Flow_Legality_Exit_From_Non_Loop) +
        Count_Status (Model, Flow_Legality_Goto_Target_Missing) +
        Count_Status (Model, Flow_Legality_Goto_Into_Deeper_Scope) +
        Count_Status (Model, Flow_Legality_Goto_Out_Of_Handler) +
        Count_Status (Model, Flow_Legality_Duplicate_Label);
   end Exit_Goto_Error_Count;

   function Exception_Error_Count (Model : Flow_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Flow_Legality_Exception_Choice_Unresolved) +
        Count_Status (Model, Flow_Legality_Exception_Choice_Duplicate) +
        Count_Status (Model, Flow_Legality_Exception_Choice_Others_Not_Last) +
        Count_Status (Model, Flow_Legality_Raise_Exception_Unresolved);
   end Exception_Error_Count;

   function Tasking_Error_Count (Model : Flow_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Flow_Legality_Select_Alternative_Error) +
        Count_Status (Model, Flow_Legality_Accept_Entry_Missing) +
        Count_Status (Model, Flow_Legality_Requeue_Target_Unresolved);
   end Tasking_Error_Count;

   function Return_Path_Error_Count (Model : Flow_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Flow_Legality_Missing_Return_Path) +
        Count_Status (Model, Flow_Legality_Return_Path_Contains_Illegal_Return);
   end Return_Path_Error_Count;

   function Fingerprint (Model : Flow_Legality_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Control_Flow_Legality;
