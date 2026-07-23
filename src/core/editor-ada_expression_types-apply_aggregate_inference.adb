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
   procedure Apply_Aggregate_Inference
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Types   : Editor.Ada_Type_Graph.Type_Model;
      Info    : in out Expression_Type_Info;
      Node    : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text : constant String := To_String (Node.Label);
      Expected : constant String := To_String (Info.Expected_Subtype);
      NExpected : constant String := To_String (Info.Normalized_Expected_Subtype);
      Childs : constant Natural := Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id);
      Named  : Natural := 0;
      Positional : Natural := 0;
      Index   : constant String := Extract_Array_Index_Subtype (Expected);
      Region  : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Element : constant String := Array_Element_Subtype_For (Tree, Types, Region, Expected);
      Expected_Category : constant Editor.Ada_Type_Graph.Type_Category :=
        Type_Category_For_Subtype (Types, Region, Expected);
      Record_Missing : Natural := 0;
      Record_Duplicate : Natural := 0;
      Record_Compatible : Natural := 0;
      Array_Compatible : Natural := 0;
      Array_Mismatch : Natural := 0;
      Array_Unknown : Natural := 0;
   begin
      if not (Node.Kind = Editor.Ada_Syntax_Tree.Node_Aggregate or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Delta_Aggregate or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Container_Aggregate)
      then
         Info.Aggregate_Status := Aggregate_Type_Not_Aggregate;
         return;
      end if;

      Info.Aggregate_Status := Aggregate_Type_Context_Required;
      Info.Aggregate_Component_Count :=
        (if Childs > 0 then Childs else Top_Level_Association_Count (Text));

      for I in 1 .. Childs loop
         declare
            Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
              Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, I);
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
            CText : constant String := To_String (Child.Label);
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association or else
              Contains (CText, "=>")
            then
               Named := Named + 1;
            elsif Child.Kind = Editor.Ada_Syntax_Tree.Node_Positional_Association or else
              Child.Kind in Editor.Ada_Syntax_Tree.Node_Expression .. Editor.Ada_Syntax_Tree.Node_Allocator
            then
               Positional := Positional + 1;
            end if;
         end;
      end loop;

      if Childs = 0 then
         if Contains (Text, "=>") then
            Named := Top_Level_Association_Count (Text);
         elsif Trim (Text) /= "" then
            Positional := Top_Level_Association_Count (Text);
         end if;
      end if;

      Info.Aggregate_Named_Association_Count := Named;
      Info.Aggregate_Positional_Association_Count := Positional;

      if NExpected = "" then
         Info.Aggregate_Unknown_Count := 1;
         return;
      end if;

      Info.Inferred_Subtype := Info.Expected_Subtype;
      Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
      Info.Aggregate_Element_Subtype := To_Unbounded_String (Element);
      Info.Normalized_Aggregate_Element_Subtype := To_Unbounded_String (Normalize (Element));
      Info.Aggregate_Index_Subtype := To_Unbounded_String (Index);
      Info.Normalized_Aggregate_Index_Subtype := To_Unbounded_String (Normalize (Index));

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Delta_Aggregate then
         Info.Aggregate_Status := Aggregate_Type_Delta_Context;
      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Container_Aggregate or else
        Looks_Container_Aggregate (Text)
      then
         Info.Aggregate_Status := Aggregate_Type_Container_Context;
      elsif Contains (NExpected, "array") or else Contains (NExpected, "string") or else
        Element /= "" or else Positional > 0
      then
         Info.Aggregate_Status := Aggregate_Type_Array_Context;
      elsif Looks_Record_Aggregate (Text) or else Named > 0 then
         Info.Aggregate_Status := Aggregate_Type_Record_Context;
      else
         Info.Aggregate_Status := Aggregate_Type_Unknown;
         Info.Aggregate_Unknown_Count := 1;
      end if;

      if Expected_Category = Editor.Ada_Type_Graph.Type_Category_Record or else
        Info.Aggregate_Status = Aggregate_Type_Record_Context
      then
         for I in 1 .. Childs loop
            declare
               Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, I);
               Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
               Name : constant String := Aggregate_Association_Name (To_String (Child.Label));
            begin
               if Name /= "" then
                  declare
                     Seen : Natural := 0;
                  begin
                     for J in 1 .. Childs loop
                        declare
                           Other_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                             Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, J);
                           Other : constant Editor.Ada_Syntax_Tree.Node_Info :=
                             Editor.Ada_Syntax_Tree.Node (Tree, Other_Id);
                        begin
                           if Normalize (Aggregate_Association_Name (To_String (Other.Label))) =
                             Normalize (Name)
                           then
                              Seen := Seen + 1;
                           end if;
                        end;
                     end loop;
                     if Seen > 1 then
                        Record_Duplicate := Record_Duplicate + 1;
                     elsif Record_Component_Known (Tree, Types, Region, Expected, Name) then
                        Record_Compatible := Record_Compatible + 1;
                     elsif Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Expected) /=
                       Editor.Ada_Type_Graph.No_Type
                     then
                        Record_Missing := Record_Missing + 1;
                     else
                        Info.Aggregate_Unknown_Count := Info.Aggregate_Unknown_Count + 1;
                     end if;
                  end;
               end if;
            end;
         end loop;

         if Childs = 0 then
            for I in 1 .. Top_Level_Association_Count (Text) loop
               declare
                  Assoc : constant String := Top_Level_Association_At (Text, I);
                  Name : constant String := Aggregate_Association_Name (Assoc);
               begin
                  if Name /= "" then
                     declare
                        Seen : Natural := 0;
                     begin
                        for J in 1 .. Top_Level_Association_Count (Text) loop
                           if Normalize (Aggregate_Association_Name
                              (Top_Level_Association_At (Text, J))) =
                             Normalize (Name)
                           then
                              Seen := Seen + 1;
                           end if;
                        end loop;
                        if Seen > 1 then
                           Record_Duplicate := Record_Duplicate + 1;
                        elsif Record_Component_Known (Tree, Types, Region, Expected, Name) then
                           Record_Compatible := Record_Compatible + 1;
                        elsif Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Expected) /=
                          Editor.Ada_Type_Graph.No_Type
                        then
                           Record_Missing := Record_Missing + 1;
                        else
                           Info.Aggregate_Unknown_Count := Info.Aggregate_Unknown_Count + 1;
                        end if;
                     end;
                  end if;
               end;
            end loop;
         end if;

         Info.Aggregate_Record_Component_Compatible_Count := Record_Compatible;
         Info.Aggregate_Record_Component_Missing_Count := Record_Missing;
         Info.Aggregate_Record_Component_Duplicate_Count := Record_Duplicate;

         if Record_Duplicate > 0 then
            Info.Aggregate_Status := Aggregate_Type_Record_Component_Duplicate;
            Info.Aggregate_Mismatch_Count := Info.Aggregate_Mismatch_Count + Record_Duplicate;
         elsif Record_Missing > 0 then
            Info.Aggregate_Status := Aggregate_Type_Record_Component_Missing;
            Info.Aggregate_Mismatch_Count := Info.Aggregate_Mismatch_Count + Record_Missing;
         elsif Record_Compatible > 0 then
            Info.Aggregate_Status := Aggregate_Type_Record_Components_Compatible;
         end if;
      elsif Expected_Category = Editor.Ada_Type_Graph.Type_Category_Array or else
        Info.Aggregate_Status = Aggregate_Type_Array_Context
      then
         for I in 1 .. Childs loop
            declare
               Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, I);
               Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
               Value : constant String := Aggregate_Association_Value (To_String (Child.Label));
            begin
               if Element = "" then
                  Array_Unknown := Array_Unknown + 1;
               elsif Looks_Element_Compatible (Value, Element) then
                  Array_Compatible := Array_Compatible + 1;
               else
                  Array_Mismatch := Array_Mismatch + 1;
               end if;
            end;
         end loop;

         if Childs = 0 then
            for I in 1 .. Top_Level_Association_Count (Text) loop
               declare
                  Value : constant String := Aggregate_Association_Value
                    (Top_Level_Association_At (Text, I));
               begin
                  if Element = "" then
                     Array_Unknown := Array_Unknown + 1;
                  elsif Looks_Element_Compatible (Value, Element) then
                     Array_Compatible := Array_Compatible + 1;
                  else
                     Array_Mismatch := Array_Mismatch + 1;
                  end if;
               end;
            end loop;
         end if;

         Info.Aggregate_Array_Element_Compatible_Count := Array_Compatible;
         Info.Aggregate_Array_Element_Mismatch_Count := Array_Mismatch;
         Info.Aggregate_Array_Element_Unknown_Count := Array_Unknown;

         if Array_Mismatch > 0 then
            Info.Aggregate_Status := Aggregate_Type_Array_Element_Mismatch;
            Info.Aggregate_Mismatch_Count := Info.Aggregate_Mismatch_Count + Array_Mismatch;
         elsif Array_Unknown > 0 then
            Info.Aggregate_Status := Aggregate_Type_Array_Element_Unknown;
            Info.Aggregate_Unknown_Count := Info.Aggregate_Unknown_Count + Array_Unknown;
         elsif Array_Compatible > 0 then
            Info.Aggregate_Status := Aggregate_Type_Array_Elements_Compatible;
         end if;
      end if;

      if Info.Aggregate_Status = Aggregate_Type_Array_Context and then Named > 0 and then
        not Contains (NExpected, "array") and then Element = ""
      then
         Info.Aggregate_Status := Aggregate_Type_Mismatch;
         Info.Aggregate_Mismatch_Count := 1;
      elsif Info.Aggregate_Status /= Aggregate_Type_Unknown
        and then Info.Aggregate_Status /= Aggregate_Type_Record_Component_Missing
        and then Info.Aggregate_Status /= Aggregate_Type_Record_Component_Duplicate
        and then Info.Aggregate_Status /= Aggregate_Type_Array_Element_Mismatch
        and then Info.Aggregate_Status /= Aggregate_Type_Array_Element_Unknown
      then
         Info.Aggregate_Status := Aggregate_Type_Compatible;
      end if;
   end Apply_Aggregate_Inference;
