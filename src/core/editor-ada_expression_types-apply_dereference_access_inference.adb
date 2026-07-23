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
   procedure Apply_Dereference_Access_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text   : constant String := To_String (Node.Label);
      NText  : constant String := Normalize (Text);
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
   begin
      Info.Dereference_Access_Status := Dereference_Access_Not_Dereference_Or_Access;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Explicit_Dereference then
         declare
            Mark : constant Natural := Ada.Strings.Fixed.Index (NText, ".all");
            Prefix : constant String :=
              (if Mark = 0 or else Mark <= Text'First then "" else Trim (Text (Text'First .. Mark - 1)));
            Decl : Editor.Ada_Direct_Visibility.Declaration_Id;
            Candidate_Count : Natural := 0;
            Prefix_Subtype : constant String :=
              Object_Subtype_For_Name
                (Tree, Regions, Visibility, Region, Prefix, Decl, Candidate_Count);
            Prefix_Type : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
            Designated : Ada.Strings.Unbounded.Unbounded_String;
         begin
            Info.Status := Expression_Type_Dereference;
            Info.Candidate_Count := Candidate_Count;
            if Prefix = "" or else Decl = Editor.Ada_Direct_Visibility.No_Declaration then
               Info.Dereference_Access_Status := Dereference_Prefix_Unresolved;
               Info.Inferred_Subtype := To_Unbounded_String ("dereference_result_unknown");
               Info.Normalized_Subtype := To_Unbounded_String ("dereference_result_unknown");
               return;
            end if;

            Info.Declaration := Decl;
            Info.Dereference_Prefix_Subtype := To_Unbounded_String (Prefix_Subtype);
            Info.Normalized_Dereference_Prefix_Subtype :=
              To_Unbounded_String (Normalize (Prefix_Subtype));
            Prefix_Type := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Prefix_Subtype);
            Info.Type_Id := Prefix_Type;
            if Prefix_Type = Editor.Ada_Type_Graph.No_Type and then
              Strip_Access_Qualifiers (Prefix_Subtype) /= ""
            then
               Designated := To_Unbounded_String (Strip_Access_Qualifiers (Prefix_Subtype));
            elsif Prefix_Type /= Editor.Ada_Type_Graph.No_Type then
               Designated := To_Unbounded_String
                 (Designated_Subtype_For_Access_Type (Tree, Types, Prefix_Type));
            end if;

            if Prefix_Type = Editor.Ada_Type_Graph.No_Type and then To_String (Designated) = "" then
               Info.Dereference_Access_Status := Dereference_Prefix_Not_Access_Type;
               Info.Inferred_Subtype := To_Unbounded_String ("dereference_result_unknown");
               Info.Normalized_Subtype := To_Unbounded_String ("dereference_result_unknown");
            elsif To_String (Designated) = "" then
               Info.Dereference_Access_Status := Dereference_Designated_Subtype_Unknown;
               Info.Inferred_Subtype := To_Unbounded_String ("dereference_designated_unknown");
               Info.Normalized_Subtype := To_Unbounded_String ("dereference_designated_unknown");
            else
               Info.Dereference_Access_Status := Dereference_Designated_Subtype_Known;
               Info.Dereference_Designated_Subtype := Designated;
               Info.Normalized_Dereference_Designated_Subtype :=
                 To_Unbounded_String (Normalize (To_String (Designated)));
               Info.Inferred_Subtype := Info.Dereference_Designated_Subtype;
               Info.Normalized_Subtype := Info.Normalized_Dereference_Designated_Subtype;
            end if;
         end;
      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Attribute_Reference then
         declare
            Prefix : constant String := Attribute_Prefix_From_Text (Text);
            Attr   : constant String := Normalize (Attribute_Name_From_Text (Text));
            Decl : Editor.Ada_Direct_Visibility.Declaration_Id;
            Candidate_Count : Natural := 0;
            Target_Subtype : constant String :=
              Object_Subtype_For_Name
                (Tree, Regions, Visibility, Region, Prefix, Decl, Candidate_Count);
            Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
         begin
            if not (Attr = "access" or else Attr = "unchecked_access" or else
                    Attr = "unrestricted_access")
            then
               return;
            end if;

            Info.Candidate_Count := Candidate_Count;
            if Decl = Editor.Ada_Direct_Visibility.No_Declaration or else Target_Subtype = "" then
               Info.Dereference_Access_Status := Access_Attribute_Target_Unresolved;
               Info.Access_Result_Subtype := To_Unbounded_String ("access_result_unknown");
               Info.Normalized_Access_Result_Subtype := To_Unbounded_String ("access_result_unknown");
               return;
            end if;

            Info.Declaration := Decl;
            Info.Dereference_Access_Status := Access_Attribute_Target_Resolved;
            Info.Access_Target_Subtype := To_Unbounded_String (Target_Subtype);
            Info.Normalized_Access_Target_Subtype :=
              To_Unbounded_String (Normalize (Target_Subtype));
            if Normalize (Target_Subtype) = "subprogram" then
               Result_Subtype := To_Unbounded_String ("access subprogram");
            else
               Result_Subtype := To_Unbounded_String ("access " & Target_Subtype);
            end if;
            Info.Access_Result_Subtype := Result_Subtype;
            Info.Normalized_Access_Result_Subtype :=
              To_Unbounded_String (Normalize (To_String (Result_Subtype)));
            Info.Attribute_Result_Subtype := Info.Access_Result_Subtype;
            Info.Normalized_Attribute_Result_Subtype := Info.Normalized_Access_Result_Subtype;
            Info.Inferred_Subtype := Info.Access_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Access_Result_Subtype;
            Info.Dereference_Access_Status := Access_Attribute_Result_Known;
         end;
      end if;
   end Apply_Dereference_Access_Inference;
