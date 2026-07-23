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
with Editor.Ada_Expression_Types.Model_Accessors;
with Editor.Ada_Expression_Types.Operator_Helpers;
with Editor.Ada_Expression_Types.Statistics;
with Editor.Ada_Use_Type_Operators;
with Editor.Ada_Expression_Types.Status_Helpers;

separate (Editor.Ada_Expression_Types)
   function Infer_One
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Node       : Editor.Ada_Syntax_Tree.Node_Info) return Expression_Type_Info
   is
      Label      : constant String := Trim (To_String (Node.Label));
      Normalized : constant String := Normalize (Label);
      Region     : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Info       : Expression_Type_Info;
   begin
      Info.Node := Node.Id;
      Info.Region := Region;
      Info.Expression_Text := To_Unbounded_String (Label);
      Info.Normalized_Text := To_Unbounded_String (Normalized);
      Info.Start_Line := Node.Source_Span.Start_Line;
      Info.End_Line := Node.Source_Span.End_Line;

      case Node.Kind is
         when Editor.Ada_Syntax_Tree.Node_Literal =>
            declare
               Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                 Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, Label);
            begin
               Info.Static_Status := Value.Status;
               if Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
                  Info.Status := Expression_Type_Static_Integer;
                  Info.Inferred_Subtype := To_Unbounded_String ("Universal_Integer");
                  Info.Normalized_Subtype := To_Unbounded_String ("universal_integer");
               elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
                  Info.Status := Expression_Type_Static_Real;
                  Info.Inferred_Subtype := To_Unbounded_String ("Universal_Real");
                  Info.Normalized_Subtype := To_Unbounded_String ("universal_real");
               elsif Is_String_Literal (Label) then
                  Info.Status := Expression_Type_String_Literal;
                  Info.Inferred_Subtype := To_Unbounded_String ("String");
                  Info.Normalized_Subtype := To_Unbounded_String ("string");
               elsif Normalized = "true" or else Normalized = "false" then
                  Info.Status := Expression_Type_Boolean_Literal;
                  Info.Inferred_Subtype := To_Unbounded_String ("Boolean");
                  Info.Normalized_Subtype := To_Unbounded_String ("boolean");
               elsif Normalized = "null" then
                  Info.Status := Expression_Type_Null_Literal;
                  Info.Inferred_Subtype := To_Unbounded_String ("universal_access");
                  Info.Normalized_Subtype := To_Unbounded_String ("universal_access");
               else
                  Info.Status := Expression_Type_Indeterminate;
                  if Looks_Real (Label) then
                     Info.Inferred_Subtype := To_Unbounded_String ("Universal_Real");
                     Info.Normalized_Subtype := To_Unbounded_String ("universal_real");
                  end if;
               end if;
            end;

         when Editor.Ada_Syntax_Tree.Node_Statement_Action =>
            declare
               Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                 Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, Label);
            begin
               Info.Static_Status := Value.Status;
               if Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
                  Info.Status := Expression_Type_Static_Integer;
                  Info.Inferred_Subtype := To_Unbounded_String ("Universal_Integer");
                  Info.Normalized_Subtype := To_Unbounded_String ("universal_integer");
               elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
                  Info.Status := Expression_Type_Static_Real;
                  Info.Inferred_Subtype := To_Unbounded_String ("Universal_Real");
                  Info.Normalized_Subtype := To_Unbounded_String ("universal_real");
               elsif Is_String_Literal (Label) then
                  Info.Status := Expression_Type_String_Literal;
                  Info.Inferred_Subtype := To_Unbounded_String ("String");
                  Info.Normalized_Subtype := To_Unbounded_String ("string");
               elsif Normalized = "true" or else Normalized = "false" then
                  Info.Status := Expression_Type_Boolean_Literal;
                  Info.Inferred_Subtype := To_Unbounded_String ("Boolean");
                  Info.Normalized_Subtype := To_Unbounded_String ("boolean");
               elsif Normalized = "null" then
                  Info.Status := Expression_Type_Null_Literal;
                  Info.Inferred_Subtype := To_Unbounded_String ("universal_access");
                  Info.Normalized_Subtype := To_Unbounded_String ("universal_access");
               else
                  declare
                     Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                       Editor.Ada_Direct_Visibility.Lookup_Visible
                         (Visibility, Regions, Region, Primary_Name (Label));
                  begin
                     Info.Candidate_Count := Lookup.Match_Count;
                     if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
                        Info.Status := Expression_Type_Name_Resolved;
                        Info.Declaration := Lookup.Declaration;
                        declare
                           Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                             Editor.Ada_Direct_Visibility.Declaration
                               (Visibility, Lookup.Declaration);
                        begin
                           if Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Object
                             or else Decl.Kind =
                               Editor.Ada_Direct_Visibility.Declaration_Formal_Object
                           then
                              declare
                                 Decl_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
                                   Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
                                 Subtype_Text : constant String :=
                                   Subtype_From_Declaration_Label
                                     (To_String (Decl_Node.Label));
                              begin
                                 if Subtype_Text /= "" then
                                    Info.Inferred_Subtype :=
                                      To_Unbounded_String (Subtype_Text);
                                    Info.Normalized_Subtype :=
                                      To_Unbounded_String (Normalize (Subtype_Text));
                                 else
                                    Info.Inferred_Subtype := Decl.Name;
                                    Info.Normalized_Subtype := Decl.Normalized;
                                 end if;
                              end;
                           else
                              Info.Inferred_Subtype := Decl.Name;
                              Info.Normalized_Subtype := Decl.Normalized;
                           end if;
                           Info.Type_Id :=
                             Editor.Ada_Type_Graph.Type_For_Declaration
                               (Types, Lookup.Declaration);
                        end;
                     elsif Lookup.Status =
                       Editor.Ada_Direct_Visibility.Lookup_Ambiguous
                     then
                        Info.Status := Expression_Type_Name_Ambiguous;
                     else
                        Info.Status := Expression_Type_Indeterminate;
                     end if;
                  end;
               end if;
            end;

         when Editor.Ada_Syntax_Tree.Node_Name =>
            declare
               Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                 Editor.Ada_Direct_Visibility.Lookup_Visible
                   (Visibility, Regions, Region, Primary_Name (Label));
            begin
               Info.Candidate_Count := Lookup.Match_Count;
               if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
                  Info.Status := Expression_Type_Name_Resolved;
                  Info.Declaration := Lookup.Declaration;
                  declare
                     Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                       Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
                  begin
                     if Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Object or else
                       Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Formal_Object
                     then
                        declare
                           Decl_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
                             Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
                           Subtype_Text : constant String :=
                             Subtype_From_Declaration_Label (To_String (Decl_Node.Label));
                        begin
                           if Subtype_Text /= "" then
                              Info.Inferred_Subtype := To_Unbounded_String (Subtype_Text);
                              Info.Normalized_Subtype := To_Unbounded_String (Normalize (Subtype_Text));
                           else
                              Info.Inferred_Subtype := Decl.Name;
                              Info.Normalized_Subtype := Decl.Normalized;
                           end if;
                        end;
                     else
                        Info.Inferred_Subtype := Decl.Name;
                        Info.Normalized_Subtype := Decl.Normalized;
                     end if;
                     Info.Type_Id := Editor.Ada_Type_Graph.Type_For_Declaration (Types, Lookup.Declaration);
                  end;
               elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
                  Info.Status := Expression_Type_Name_Ambiguous;
               else
                  Info.Status := Expression_Type_Name_Unresolved;
               end if;
            end;

         when Editor.Ada_Syntax_Tree.Node_Selected_Name =>
            if Info.Status = Expression_Type_Selected_Name_Unresolved then
               declare
                  Selector : constant String := Suffix_After (Label, '.');
                  Lookup   : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                    Editor.Ada_Direct_Visibility.Lookup_Visible
                      (Visibility, Regions, Region, Selector);
               begin
                  Info.Candidate_Count := Lookup.Match_Count;
                  if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
                     Info.Status := Expression_Type_Selected_Name_Resolved;
                     Info.Declaration := Lookup.Declaration;
                  elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
                     Info.Status := Expression_Type_Name_Ambiguous;
                  else
                     Info.Status := Expression_Type_Selected_Name_Unresolved;
                  end if;
               end;
            end if;

         when Editor.Ada_Syntax_Tree.Node_Function_Call | Editor.Ada_Syntax_Tree.Node_Call_Statement =>
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call then
               Apply_Conversion_Inference (Tree, Regions, Visibility, Types, Static, Info, Node);
            end if;
            if Info.Conversion_Status = Conversion_Type_Not_Conversion or else
              Info.Conversion_Status = Conversion_Type_Target_Unresolved
            then
               declare
                  Resolution : constant Editor.Ada_Call_Resolution.Call_Resolution_Info :=
                    Editor.Ada_Call_Resolution.Resolution_For_Node (Calls, Node.Id);
               begin
                  Info.Call_Resolution := Resolution.Id;
                  Info.Candidate_Count := Resolution.Candidate_Count;
                  if Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Unique_Profile_Match then
                     Info.Status := Expression_Type_Call_Resolved;
                     Info.Declaration := Resolution.Declaration;
                  elsif Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Pre_Profile or else
                    Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Profile_Match
                  then
                     Info.Status := Expression_Type_Call_Ambiguous;
                  else
                     Info.Status := Expression_Type_Call_Unresolved;
                  end if;
               end;
            end if;

         when Editor.Ada_Syntax_Tree.Node_Operator_Expression |
              Editor.Ada_Syntax_Tree.Node_Unary_Expression |
              Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression |
              Editor.Ada_Syntax_Tree.Node_Membership_Expression =>
            Apply_Operator_Inference
              (Tree, Regions, Visibility, Types, Static, Calls, Info, Node);

         when Editor.Ada_Syntax_Tree.Node_Qualified_Expression =>
            declare
               Prefix : constant String := Prefix_Before (Label, Character'Val (39));
            begin
               Info.Status := Expression_Type_Qualified;
               Info.Inferred_Subtype := To_Unbounded_String (Prefix);
               Info.Normalized_Subtype := To_Unbounded_String (Normalize (Prefix));
               Info.Type_Id := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Prefix);
               Apply_Conversion_Inference (Tree, Regions, Visibility, Types, Static, Info, Node);
            end;

         when Editor.Ada_Syntax_Tree.Node_Aggregate |
              Editor.Ada_Syntax_Tree.Node_Delta_Aggregate |
              Editor.Ada_Syntax_Tree.Node_Container_Aggregate =>
            Info.Status := Expression_Type_Aggregate;
            Info.Inferred_Subtype := To_Unbounded_String ("aggregate_context_required");
            Info.Normalized_Subtype := To_Unbounded_String ("aggregate_context_required");

         when Editor.Ada_Syntax_Tree.Node_Indexed_Component =>
            Info.Status := Expression_Type_Indexed_Component;
            Info.Inferred_Subtype := To_Unbounded_String ("indexed_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("indexed_result_unknown");

         when Editor.Ada_Syntax_Tree.Node_Explicit_Dereference =>
            Info.Status := Expression_Type_Dereference;
            Info.Inferred_Subtype := To_Unbounded_String ("dereference_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("dereference_result_unknown");

         when Editor.Ada_Syntax_Tree.Node_Allocator =>
            Info.Status := Expression_Type_Allocator;
            Info.Inferred_Subtype := To_Unbounded_String ("allocator_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("allocator_result_unknown");

         when Editor.Ada_Syntax_Tree.Node_Slice =>
            Info.Status := Expression_Type_Slice;
            Info.Inferred_Subtype := To_Unbounded_String ("slice_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("slice_result_unknown");

         when Editor.Ada_Syntax_Tree.Node_Attribute_Reference =>
            Info.Status := Expression_Type_Attribute;
            declare
               Prefix : constant String := Attribute_Prefix_From_Text (Label);
               Attr   : constant String := Attribute_Name_From_Text (Label);
               NAttr  : constant String := Normalize (Attr);
               Prefix_Type : constant Editor.Ada_Type_Graph.Type_Id :=
                 Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Prefix);
            begin
               Info.Attribute_Name := To_Unbounded_String (Attr);
               Info.Normalized_Attribute_Name := To_Unbounded_String (NAttr);
               Info.Attribute_Prefix := To_Unbounded_String (Prefix);
               Info.Normalized_Attribute_Prefix := To_Unbounded_String (Normalize (Prefix));
               Info.Attribute_Prefix_Type := Prefix_Type;

               if Prefix = "" or else Attr = "" then
                  Info.Attribute_Status := Attribute_Type_Malformed;
                  Info.Inferred_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Normalized_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Attribute_Unknown_Count := 1;
               elsif Prefix_Type = Editor.Ada_Type_Graph.No_Type and then
                 not (NAttr = "access" or else NAttr = "unchecked_access" or else
                      NAttr = "unrestricted_access") and then
                 not (Normalize (Prefix) = "standard" or else Contains (Normalize (Prefix), "."))
               then
                  Info.Attribute_Status := Attribute_Type_Prefix_Unresolved;
                  Info.Inferred_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Normalized_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Attribute_Unknown_Count := 1;
               elsif NAttr = "first" or else NAttr = "last" then
                  Info.Attribute_Status := Attribute_Type_Scalar_Bound;
                  Info.Attribute_Result_Subtype := To_Unbounded_String (Prefix);
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String (Normalize (Prefix));
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
                  Info.Attribute_Static_Result_Count := 1;
               elsif NAttr = "range" then
                  Info.Attribute_Status := Attribute_Type_Range_Bound;
                  Info.Attribute_Result_Subtype := To_Unbounded_String (Prefix & " range");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String (Normalize (Prefix & " range"));
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               elsif NAttr = "length" or else NAttr = "pos" or else
                 NAttr = "max_size_in_storage_elements" then
                  Info.Attribute_Status := Attribute_Type_Integer_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("Universal_Integer");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String ("universal_integer");
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
                  Info.Attribute_Static_Result_Count := 1;
               elsif NAttr = "val" or else NAttr = "succ" or else NAttr = "pred" then
                  Info.Attribute_Status := Attribute_Type_Value_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String (Prefix);
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String (Normalize (Prefix));
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               elsif NAttr = "image" or else NAttr = "wide_image" or else
                 NAttr = "wide_wide_image" or else NAttr = "img" then
                  Info.Attribute_Status := Attribute_Type_String_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("String");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String ("string");
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
                  Info.Attribute_String_Result_Count := 1;
               elsif NAttr = "value" then
                  Info.Attribute_Status := Attribute_Type_Value_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String (Prefix);
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String (Normalize (Prefix));
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               elsif NAttr = "address" then
                  Info.Attribute_Status := Attribute_Type_Address_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("System.Address");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String ("system.address");
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               elsif NAttr = "size" or else NAttr = "object_size" or else
                 NAttr = "value_size" or else NAttr = "component_size" or else
                 NAttr = "alignment" or else NAttr = "storage_size" then
                  Info.Attribute_Status := Attribute_Type_Size_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("Universal_Integer");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String ("universal_integer");
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
                  Info.Attribute_Static_Result_Count := 1;
               elsif NAttr = "callable" or else NAttr = "terminated" then
                  Info.Attribute_Status := Attribute_Type_Boolean_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("Boolean");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String ("boolean");
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               elsif NAttr = "access" or else NAttr = "unchecked_access" or else
                 NAttr = "unrestricted_access" then
                  Info.Attribute_Status := Attribute_Type_Callable_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("access " & Prefix);
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String (Normalize ("access " & Prefix));
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               else
                  Info.Attribute_Status := Attribute_Type_Unknown_Attribute;
                  Info.Inferred_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Normalized_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Attribute_Unknown_Count := 1;
               end if;
            end;

         when Editor.Ada_Syntax_Tree.Node_Parenthesized_Expression |
              Editor.Ada_Syntax_Tree.Node_Expression |
              Editor.Ada_Syntax_Tree.Node_Conditional_Expression |
              Editor.Ada_Syntax_Tree.Node_Case_Expression |
              Editor.Ada_Syntax_Tree.Node_Quantified_Expression |
              Editor.Ada_Syntax_Tree.Node_Declare_Expression |
              Editor.Ada_Syntax_Tree.Node_Reduction_Expression |
              Editor.Ada_Syntax_Tree.Node_Target_Name |
              Editor.Ada_Syntax_Tree.Node_Range_Expression =>
            Info.Status := Expression_Type_Indeterminate;

         when others =>
            Info.Status := Expression_Type_Not_Checked;
      end case;

      return Info;
   end Infer_One;
