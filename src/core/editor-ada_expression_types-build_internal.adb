with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Expression_Types.Cross_Unit_Selected_Subtype_Refinement;
with Editor.Ada_Expression_Types.Access_Text_Helpers;
with Editor.Ada_Expression_Types.Inference_Support;
with Editor.Ada_Expression_Types.Call_Inference;
with Editor.Ada_Expression_Types.Call_Text_Helpers;
with Editor.Ada_Expression_Types.Operator_Helpers;
with Editor.Ada_Expression_Types.Statistics;
with Editor.Ada_Use_Type_Operators;
with Editor.Ada_Expression_Types.Status_Helpers;


separate (Editor.Ada_Expression_Types)
   function Build_Internal
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Use_Selected : Boolean;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Use_Expected : Boolean;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Use_Primitives : Boolean)
      return Expression_Type_Model
   is
      Model : Expression_Type_Model;

      function Wrapper_Can_Inherit
        (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean is
      begin
         return Kind = Editor.Ada_Syntax_Tree.Node_Expression
           or else Kind = Editor.Ada_Syntax_Tree.Node_Parenthesized_Expression;
      end Wrapper_Can_Inherit;

      procedure Propagate_Single_Child_Subtypes is
      begin
         for Pass in 1 .. 3 loop
            declare
               Source  : constant Expression_Type_Model := Model;
               Refined : Expression_Type_Model;
            begin
               for I in 1 .. Natural (Source.Expressions.Length) loop
                  declare
                     Info : Expression_Type_Info := Source.Expressions.Element (I);
                     Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
                       Editor.Ada_Syntax_Tree.Node (Tree, Info.Node);
                     Child_Info : Expression_Type_Info := (others => <>);
                     Candidate_Count : Natural := 0;
                  begin
                     if Wrapper_Can_Inherit (Node.Kind)
                       and then (To_String (Info.Normalized_Subtype) = ""
                                 or else Info.Expected_Status = Expected_Type_Propagated)
                     then
                        for Child_Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) loop
                           declare
                              Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                                Editor.Ada_Syntax_Tree.Child_At
                                  (Tree, Node.Id, Child_Index);
                              Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                                Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
                              Candidate : constant Expression_Type_Info :=
                                Expression_Type_For_Node (Source, Child_Id);
                           begin
                              if Child.Kind in Editor.Ada_Syntax_Tree.Node_Expression ..
                                Editor.Ada_Syntax_Tree.Node_Allocator
                                and then To_String (Candidate.Normalized_Subtype) /= ""
                              then
                                 Candidate_Count := Candidate_Count + 1;
                                 Child_Info := Candidate;
                              end if;
                           end;
                        end loop;

                        if Candidate_Count = 1 then
                           Info.Status := Child_Info.Status;
                           Info.Inferred_Subtype := Child_Info.Inferred_Subtype;
                           Info.Normalized_Subtype := Child_Info.Normalized_Subtype;
                           if To_String (Info.Normalized_Expected_Subtype) /= "" then
                              if To_String (Info.Normalized_Subtype) =
                                To_String (Info.Normalized_Expected_Subtype)
                                or else Is_Universal_Compatible
                                  (To_String (Info.Normalized_Subtype),
                                   To_String (Info.Normalized_Expected_Subtype))
                              then
                                 Info.Expected_Status := Expected_Type_Compatible;
                              else
                                 Info.Expected_Status := Expected_Type_Mismatch;
                              end if;
                           end if;
                        end if;
                     end if;

                     Append (Refined, Info);
                  end;
               end loop;

               Model := Refined;
            end;
         end loop;
      end Propagate_Single_Child_Subtypes;
   begin
      for I in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            N : constant Editor.Ada_Syntax_Tree.Node_Info := Editor.Ada_Syntax_Tree.Node_At (Tree, I);
         begin
            if N.Kind in Editor.Ada_Syntax_Tree.Node_Expression .. Editor.Ada_Syntax_Tree.Node_Allocator
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Statement_Action
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Raise_Statement
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Association
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Positional_Association
            then
               declare
                  Info : Expression_Type_Info :=
                    Infer_One (Tree, Regions, Visibility, Types, Static, Calls, N);
               begin
                  if Use_Selected and then N.Kind = Editor.Ada_Syntax_Tree.Node_Selected_Name then
                     declare
                        S : constant Editor.Ada_Selected_Name_Resolution.Selected_Name_Info :=
                          Editor.Ada_Selected_Name_Resolution.Selected_Name_For_Node (Selected, N.Id);
                     begin
                        Info.Selected_Name := S.Id;
                        Info.Selected_Name_Status := S.Status;
                        Info.Cross_Unit_Selected_Target := S.Cross_Unit_Target;
                        Info.Cross_Unit_Selected_Path := S.Cross_Unit_Path;
                        Info.Cross_Unit_Selected_Selector := S.Selector;
                        Info.Normalized_Cross_Unit_Selected_Target :=
                          To_Unbounded_String (Normalize (To_String (S.Cross_Unit_Target)));
                        Info.Normalized_Cross_Unit_Selected_Selector := S.Normalized_Selector;

                        if S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Found then
                           Info.Status := Expression_Type_Selected_Name_Resolved;
                           Info.Declaration := S.Selector_Declaration;
                           Info.Candidate_Count := 1;
                        elsif S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Found or else
                          S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Use_Prefix_Found
                        then
                           Info.Status := Expression_Type_Selected_Name_Cross_Unit_Resolved;
                           Info.Candidate_Count := 1;
                           Info.Inferred_Subtype :=
                             To_Unbounded_String
                               ("cross_unit_selected:" & To_String (S.Cross_Unit_Target) & "." &
                                To_String (S.Selector));
                           Info.Normalized_Subtype :=
                             To_Unbounded_String
                               (Normalize ("cross_unit_selected:" & To_String (S.Cross_Unit_Target) & "." &
                                           To_String (S.Selector)));
                        elsif S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Limited_Prefix then
                           Info.Status := Expression_Type_Selected_Name_Cross_Unit_Limited;
                           Info.Candidate_Count := 1;
                           Info.Inferred_Subtype := To_Unbounded_String ("limited_view_selected_name");
                           Info.Normalized_Subtype := To_Unbounded_String ("limited_view_selected_name");
                        elsif S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Private_Prefix then
                           Info.Status := Expression_Type_Selected_Name_Cross_Unit_Private;
                           Info.Candidate_Count := 1;
                           Info.Inferred_Subtype := To_Unbounded_String ("private_view_selected_name");
                           Info.Normalized_Subtype := To_Unbounded_String ("private_view_selected_name");
                        elsif S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Missing or else
                          S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Ambiguous or else
                          S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Overflow
                        then
                           Info.Status := Expression_Type_Selected_Name_Cross_Unit_Unresolved;
                        elsif S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Selector_Ambiguous or else
                          S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Prefix_Ambiguous
                        then
                           Info.Status := Expression_Type_Name_Ambiguous;
                           Info.Candidate_Count := 2;
                        elsif S.Status /= Editor.Ada_Selected_Name_Resolution.Selected_Name_Not_Resolved then
                           Info.Status := Expression_Type_Selected_Name_Unresolved;
                        end if;
                     end;
                  end if;

                  if Use_Expected then
                     Apply_Expected_Context (Info, Expected);
                     if Info.Expected_Status = Expected_Type_No_Context or else
                       Info.Expected_Status = Expected_Type_Not_Checked
                     then
                        Apply_Syntax_Expected_Context (Tree, Info);
                        if Info.Expected_Status = Expected_Type_Not_Checked then
                           Info.Expected_Status := Expected_Type_No_Context;
                        end if;
                     end if;
                  else
                     Info.Expected_Status := Expected_Type_Not_Checked;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Operator_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Unary_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Membership_Expression
                  then
                     Apply_Operator_Overload_Resolution
                       (Regions, Visibility, Primitives, Info, Use_Primitives);
                     Apply_Concatenation_Inference (Tree, Regions, Visibility, Types, Static, Info);
                  elsif Ada.Strings.Fixed.Index (To_String (Info.Expression_Text), "&") /= 0 then
                     Apply_Concatenation_Inference (Tree, Regions, Visibility, Types, Static, Info);
                  else
                     Info.Concatenation_Status := Concatenation_Type_Not_Concatenation;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Conditional_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Case_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Quantified_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Declare_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Reduction_Expression
                  then
                     Apply_Conditional_Inference
                       (Tree, Regions, Visibility, Types, Static, Calls, Info, N);
                  else
                     Info.Conditional_Status := Conditional_Type_Not_Conditional;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Membership_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Range_Expression
                  then
                     Apply_Membership_Range_Inference
                       (Tree, Regions, Visibility, Types, Static, Calls, Info, N);
                  else
                     Info.Membership_Range_Status := Membership_Range_Not_Membership_Or_Range;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Target_Name or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Delta_Aggregate
                  then
                     Apply_Target_Name_Update_Inference
                       (Tree, Regions, Visibility, Types, Static, Calls, Info, N);
                  else
                     Info.Target_Name_Status := Target_Name_Not_Target_Name_Or_Update;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Indexed_Component or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Slice
                  then
                     Apply_Indexed_Slice_Inference
                       (Tree, Regions, Visibility, Types, Static, Calls, Info, N);
                  else
                     Info.Indexed_Slice_Status := Indexed_Slice_Not_Indexed_Or_Slice;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Explicit_Dereference or else
                    (N.Kind = Editor.Ada_Syntax_Tree.Node_Attribute_Reference and then
                     (Normalize (Attribute_Name_From_Text (To_String (N.Label))) = "access" or else
                      Normalize (Attribute_Name_From_Text (To_String (N.Label))) = "unchecked_access" or else
                      Normalize (Attribute_Name_From_Text (To_String (N.Label))) = "unrestricted_access"))
                  then
                     Apply_Dereference_Access_Inference
                       (Tree, Regions, Visibility, Types, Info, N);
                  else
                     Info.Dereference_Access_Status := Dereference_Access_Not_Dereference_Or_Access;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Allocator then
                     Apply_Allocator_Inference
                       (Tree, Regions, Visibility, Types, Info, N);
                  else
                     Info.Allocator_Status := Allocator_Type_Not_Allocator;
                  end if;

                  Apply_Raise_No_Return_Inference (Tree, Visibility, Info, N);

                  Apply_Call_Actual_Type_Resolution
                    (Tree, Regions, Visibility, Static, Calls, Info, N);
                  if Info.Conversion_Status in Conversion_Type_Operand_Compatible |
                                                Conversion_Type_Operand_Requires_Explicit_Conversion |
                                                Conversion_Type_Operand_Mismatch |
                                                Conversion_Type_Operand_Unknown
                  then
                     Info.Status :=
                       (if N.Kind = Editor.Ada_Syntax_Tree.Node_Qualified_Expression then
                           Expression_Type_Qualified
                        else
                           Expression_Type_Conversion);
                  end if;

                  Apply_Dispatching_Call_Inference
                    (Tree, Regions, Visibility, Static, Info, N);

                  Apply_Parameter_Association_Inference
                    (Tree, Regions, Visibility, Static, Calls, Info, N);

                  Apply_Universal_Numeric_Resolution (Tree, Static, Regions, Info, N);

                  Apply_Boolean_Context_Inference (Info, N);

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Aggregate or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Delta_Aggregate or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Container_Aggregate
                  then
                     Apply_Aggregate_Inference (Tree, Regions, Types, Info, N);
                  else
                     Info.Aggregate_Status := Aggregate_Type_Not_Aggregate;
                  end if;

                  if not (N.Kind = Editor.Ada_Syntax_Tree.Node_Qualified_Expression or else
                          N.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call)
                  then
                     Info.Conversion_Status := Conversion_Type_Not_Conversion;
                  end if;

                  if N.Kind /= Editor.Ada_Syntax_Tree.Node_Attribute_Reference then
                     Info.Attribute_Status := Attribute_Type_Not_Attribute;
                  end if;

                  if Info.Status /= Expression_Type_Not_Checked then
                     Append (Model, Info);
                  end if;
               end;
            end if;
         end;
      end loop;
      Propagate_Single_Child_Subtypes;
      return Model;
   end Build_Internal;
