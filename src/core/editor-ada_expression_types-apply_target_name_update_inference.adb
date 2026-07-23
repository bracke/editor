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
   procedure Apply_Target_Name_Update_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Expected : Ada.Strings.Unbounded.Unbounded_String :=
        Info.Normalized_Expected_Subtype;
      Has_Source : Boolean := False;
   begin
      if To_String (Expected) = "" then
         declare
            Current : Editor.Ada_Syntax_Tree.Node_Id := Node.Parent;
         begin
            while Current /= Editor.Ada_Syntax_Tree.No_Node loop
               declare
                  Anc : constant Editor.Ada_Syntax_Tree.Node_Info :=
                    Editor.Ada_Syntax_Tree.Node (Tree, Current);
               begin
                  if Anc.Kind = Editor.Ada_Syntax_Tree.Node_Declaration_Default and then
                    Anc.Parent /= Editor.Ada_Syntax_Tree.No_Node
                  then
                     declare
                        Grand : constant Editor.Ada_Syntax_Tree.Node_Info :=
                          Editor.Ada_Syntax_Tree.Node (Tree, Anc.Parent);
                        Subtype_Text : constant String :=
                          Subtype_From_Declaration_Label (To_String (Grand.Label));
                     begin
                        if Subtype_Text /= "" then
                           Info.Expected_Subtype := To_Unbounded_String (Subtype_Text);
                           Info.Normalized_Expected_Subtype := To_Unbounded_String (Normalize (Subtype_Text));
                           Expected := Info.Normalized_Expected_Subtype;
                           exit;
                        end if;
                     end;
                  end if;
                  Current := Anc.Parent;
               end;
            end loop;
         end;
      end if;
      Info.Target_Name_Status := Target_Name_Not_Target_Name_Or_Update;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Target_Name then
         if To_String (Expected) = "" then
            Info.Target_Name_Status := Target_Name_Context_Required;
            Info.Target_Name_Unknown_Count := 1;
         else
            Info.Target_Name_Status := Target_Name_Context_Propagated;
            Info.Target_Name_Expected_Subtype := Info.Expected_Subtype;
            Info.Normalized_Target_Name_Expected_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Target_Name_Compatible_Count := 1;
         end if;
         return;
      end if;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Delta_Aggregate then
         Info.Delta_Update_Count := 1;
         Info.Target_Name_Expected_Subtype := Info.Expected_Subtype;
         Info.Normalized_Target_Name_Expected_Subtype := Info.Normalized_Expected_Subtype;

         if To_String (Expected) = "" then
            Info.Target_Name_Status := Target_Name_Context_Required;
            Info.Target_Name_Unknown_Count := 1;
            return;
         end if;

         for I in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) loop
            declare
               Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, I);
               Child    : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
               Child_Info : constant Expression_Type_Info :=
                 Infer_One (Tree, Regions, Visibility, Types, Static, Calls, Child);
               Child_Name : constant String := Normalize (To_String (Child.Label));
            begin
               if Child.Kind /= Editor.Ada_Syntax_Tree.Node_Target_Name and then
                 To_String (Child_Info.Normalized_Subtype) /= ""
               then
                  Has_Source := True;
                  Info.Target_Name_Source_Subtype := Child_Info.Inferred_Subtype;
                  Info.Normalized_Target_Name_Source_Subtype := Child_Info.Normalized_Subtype;
                  exit;
               elsif Child.Kind = Editor.Ada_Syntax_Tree.Node_Name
                 and then To_String (Expected) /= ""
                 and then Child_Name /= ""
                 and then Contains (Normalize (To_String (Node.Label)), Child_Name & " with")
               then
                  Has_Source := True;
                  Info.Target_Name_Source_Subtype := Info.Expected_Subtype;
                  Info.Normalized_Target_Name_Source_Subtype := Info.Normalized_Expected_Subtype;
                  exit;
               end if;
            end;
         end loop;

         if not Has_Source then
            Info.Target_Name_Status := Target_Name_Delta_Update_Unknown;
            Info.Target_Name_Unknown_Count := 1;
         elsif To_String (Info.Normalized_Target_Name_Source_Subtype) = To_String (Expected) or else
           Is_Universal_Compatible (To_String (Info.Normalized_Target_Name_Source_Subtype), To_String (Expected))
         then
            Info.Target_Name_Status := Target_Name_Delta_Update_Compatible;
            Info.Target_Name_Compatible_Count := 1;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
         else
            Info.Target_Name_Status := Target_Name_Delta_Update_Mismatch;
            Info.Target_Name_Mismatch_Count := 1;
         end if;
      end if;
   end Apply_Target_Name_Update_Inference;
