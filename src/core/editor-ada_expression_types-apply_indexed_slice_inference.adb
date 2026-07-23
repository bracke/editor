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
   procedure Apply_Indexed_Slice_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      pragma Unreferenced (Static, Calls);
      Text     : constant String := To_String (Node.Label);
      Prefix   : constant String := Extract_Designator_Before_Call (Text);
      Region   : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Prefix_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Prefix_Type    : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Element_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Index_Subtype   : Ada.Strings.Unbounded.Unbounded_String;
      Index_Count     : Natural := 0;
   begin
      Info.Indexed_Slice_Status := Indexed_Slice_Not_Indexed_Or_Slice;

      if not (Node.Kind = Editor.Ada_Syntax_Tree.Node_Indexed_Component or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Slice)
      then
         return;
      end if;

      if Prefix = "" then
         Info.Indexed_Slice_Status := Indexed_Slice_Prefix_Unresolved;
         Info.Indexed_Slice_Unknown_Index_Count := 1;
         return;
      end if;

      declare
         Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
           Editor.Ada_Direct_Visibility.Lookup_Visible
             (Visibility, Regions, Region, Primary_Name (Prefix));
      begin
         if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
            declare
               Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                 Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
               Subt : constant String := Subtype_From_Declaration_Label (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node).Label));
            begin
               if Subt /= "" then
                  Prefix_Subtype := To_Unbounded_String (Subt);
                  Prefix_Type := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Subt);
               else
                  Prefix_Subtype := Decl.Name;
                  Prefix_Type := Editor.Ada_Type_Graph.Type_For_Declaration (Types, Lookup.Declaration);
               end if;
            end;
         elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
            Info.Indexed_Slice_Status := Indexed_Slice_Result_Unknown;
            Info.Candidate_Count := 2;
            Info.Indexed_Slice_Unknown_Index_Count := 1;
            return;
         else
            Info.Indexed_Slice_Status := Indexed_Slice_Prefix_Unresolved;
            Info.Indexed_Slice_Unknown_Index_Count := 1;
            return;
         end if;
      end;

      Info.Indexed_Slice_Status := Indexed_Slice_Prefix_Resolved;
      Info.Indexed_Slice_Prefix_Subtype := Prefix_Subtype;
      Info.Normalized_Indexed_Slice_Prefix_Subtype :=
        To_Unbounded_String (Normalize (To_String (Prefix_Subtype)));
      Info.Type_Id := Prefix_Type;

      if Prefix_Type /= Editor.Ada_Type_Graph.No_Type then
         declare
            T : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_Node (Types, Prefix_Type);
            Base : constant String := To_String (T.Base_Subtype);
         begin
            if T.Category = Editor.Ada_Type_Graph.Type_Category_Array then
               Element_Subtype := To_Unbounded_String (Extract_Array_Element_Subtype (Base));
               Index_Subtype := To_Unbounded_String (Extract_Array_Index_Subtype (Base));
            elsif T.Category = Editor.Ada_Type_Graph.Type_Category_Subtype or else
              T.Category = Editor.Ada_Type_Graph.Type_Category_Derived
            then
               Element_Subtype := To_Unbounded_String (Extract_Array_Element_Subtype (Base));
               Index_Subtype := To_Unbounded_String (Extract_Array_Index_Subtype (Base));
            end if;
         end;
      end if;

      if To_String (Element_Subtype) = "" then
         Element_Subtype := To_Unbounded_String
           (Extract_Array_Element_Subtype (To_String (Prefix_Subtype)));
      end if;
      if To_String (Index_Subtype) = "" then
         Index_Subtype := To_Unbounded_String
           (Extract_Array_Index_Subtype (To_String (Prefix_Subtype)));
      end if;
      if To_String (Element_Subtype) = "" and then
        Contains (Normalize (To_String (Prefix_Subtype)), "string")
      then
         Element_Subtype := To_Unbounded_String ("Character");
         Index_Subtype := To_Unbounded_String ("Positive");
      end if;

      Info.Indexed_Slice_Index_Subtype := Index_Subtype;
      Info.Normalized_Indexed_Slice_Index_Subtype :=
        To_Unbounded_String (Normalize (To_String (Index_Subtype)));

      if Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) > 1 then
         Index_Count := Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) - 1;
      else
         Index_Count := Count_Commas (Text) + 1;
      end if;
      Info.Indexed_Slice_Index_Count := Index_Count;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Slice then
         Info.Status := Expression_Type_Slice;
         Info.Indexed_Slice_Result_Subtype := Prefix_Subtype;
         Info.Normalized_Indexed_Slice_Result_Subtype :=
           To_Unbounded_String (Normalize (To_String (Prefix_Subtype)));
         Info.Inferred_Subtype := Info.Indexed_Slice_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Indexed_Slice_Result_Subtype;
         Info.Indexed_Slice_Status := Indexed_Slice_Result_Array;
      elsif To_String (Element_Subtype) /= "" then
         Info.Status := Expression_Type_Indexed_Component;
         Info.Indexed_Slice_Result_Subtype := Element_Subtype;
         Info.Normalized_Indexed_Slice_Result_Subtype :=
           To_Unbounded_String (Normalize (To_String (Element_Subtype)));
         Info.Inferred_Subtype := Info.Indexed_Slice_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Indexed_Slice_Result_Subtype;
         Info.Indexed_Slice_Status := Indexed_Slice_Result_Element;
      else
         Info.Status := Expression_Type_Indexed_Component;
         Info.Inferred_Subtype := To_Unbounded_String ("indexed_result_unknown");
         Info.Normalized_Subtype := To_Unbounded_String ("indexed_result_unknown");
         Info.Indexed_Slice_Status := Indexed_Slice_Result_Unknown;
         Info.Indexed_Slice_Unknown_Index_Count := 1;
      end if;

      if To_String (Index_Subtype) = "" then
         Info.Indexed_Slice_Unknown_Index_Count := Info.Indexed_Slice_Unknown_Index_Count + 1;
      else
         Info.Indexed_Slice_Compatible_Index_Count := Index_Count;
         if Info.Indexed_Slice_Status = Indexed_Slice_Result_Element or else
           Info.Indexed_Slice_Status = Indexed_Slice_Result_Array
         then
            Info.Indexed_Slice_Status := Indexed_Slice_Index_Compatible;
         end if;
      end if;
   end Apply_Indexed_Slice_Inference;
