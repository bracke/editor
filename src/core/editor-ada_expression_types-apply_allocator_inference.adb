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
   procedure Apply_Allocator_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      pragma Unreferenced (Visibility);
      Text   : constant String := To_String (Node.Label);
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Target : constant String := Allocator_Target_From_Text (Text);
      Expected : constant String := To_String (Info.Expected_Subtype);
      NExpected : constant String := To_String (Info.Normalized_Expected_Subtype);
      Designated : Ada.Strings.Unbounded.Unbounded_String;
      Target_Type : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
   begin
      Info.Allocator_Status := Allocator_Type_Not_Allocator;
      if Node.Kind /= Editor.Ada_Syntax_Tree.Node_Allocator then
         return;
      end if;

      Info.Status := Expression_Type_Allocator;
      if Target = "" then
         Info.Allocator_Status := Allocator_Type_Malformed;
         Info.Inferred_Subtype := To_Unbounded_String ("allocator_result_unknown");
         Info.Normalized_Subtype := To_Unbounded_String ("allocator_result_unknown");
         return;
      end if;

      Info.Allocator_Target_Subtype := To_Unbounded_String (Target);
      Info.Normalized_Allocator_Target_Subtype := To_Unbounded_String (Normalize (Target));
      Target_Type := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Target);
      if Target_Type /= Editor.Ada_Type_Graph.No_Type then
         Info.Type_Id := Target_Type;
         Info.Allocator_Status := Allocator_Type_Target_Resolved;
      else
         --  Keep predefined and still-unindexed target subtype marks as staged
         --  subtype text.  A later full type checker can decide whether the
         --  target is a legal subtype mark; this pass should not drop useful
         --  allocator metadata merely because the type graph is incomplete.
         Info.Allocator_Status := Allocator_Type_Target_Unresolved;
      end if;

      if NExpected /= "" then
         Info.Allocator_Expected_Access_Subtype := Info.Expected_Subtype;
         Info.Normalized_Allocator_Expected_Access_Subtype := Info.Normalized_Expected_Subtype;
         Designated := To_Unbounded_String (Expected_Access_Designated_Subtype (Expected));
         if To_String (Designated) = "" then
            declare
               Expected_Type : constant Editor.Ada_Type_Graph.Type_Id :=
                 Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Expected);
            begin
               if Expected_Type /= Editor.Ada_Type_Graph.No_Type then
                  Designated := To_Unbounded_String
                    (Designated_Subtype_For_Access_Type (Tree, Types, Expected_Type));
               end if;
            end;
         end if;
         if To_String (Designated) = "" then
            Info.Allocator_Status := Allocator_Type_Expected_Not_Access;
            Info.Allocator_Result_Subtype := To_Unbounded_String ("allocator_result_unknown");
            Info.Normalized_Allocator_Result_Subtype := To_Unbounded_String ("allocator_result_unknown");
            Info.Inferred_Subtype := Info.Allocator_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Allocator_Result_Subtype;
            return;
         end if;

         Info.Allocator_Designated_Subtype := Designated;
         Info.Normalized_Allocator_Designated_Subtype :=
           To_Unbounded_String (Normalize (To_String (Designated)));
         Info.Allocator_Result_Subtype := Info.Expected_Subtype;
         Info.Normalized_Allocator_Result_Subtype := Info.Normalized_Expected_Subtype;
         Info.Inferred_Subtype := Info.Allocator_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Allocator_Result_Subtype;

         if Normalize (Target) = Normalize (To_String (Designated)) or else
           Subtype_Compatible_By_Graph (Types, Region, To_String (Designated), Target)
         then
            Info.Allocator_Status := Allocator_Type_Designated_Compatible;
         else
            Info.Allocator_Status := Allocator_Type_Designated_Mismatch;
         end if;
      else
         Info.Allocator_Result_Subtype := To_Unbounded_String ("access " & Target);
         Info.Normalized_Allocator_Result_Subtype :=
           To_Unbounded_String (Normalize ("access " & Target));
         Info.Inferred_Subtype := Info.Allocator_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Allocator_Result_Subtype;
         Info.Allocator_Designated_Subtype := To_Unbounded_String (Target);
         Info.Normalized_Allocator_Designated_Subtype := To_Unbounded_String (Normalize (Target));
         Info.Allocator_Status := Allocator_Type_Result_Known;
      end if;
   end Apply_Allocator_Inference;
