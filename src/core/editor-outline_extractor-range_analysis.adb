with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Outline;
with Editor.Outline_Extractor.Detail_Parsing;
with Editor.Outline_Extractor.Line_Analysis;
with Editor.Outline_Extractor.Structure_Analysis;

package body Editor.Outline_Extractor.Range_Analysis is

   use type Editor.Outline.Outline_Item_Kind;
   use Editor.Outline_Extractor.Line_Analysis;

   function Has_Field_Row_For_Object
     (Result : Extraction_Result;
      Object : Editor.Outline.Outline_Item) return Boolean
   is
      Label : constant String := To_String (Object.Label);
      Name  : constant String :=
        (if Starts_With (Label, "object ")
         then Label (Label'First + 7 .. Label'Last)
         else "");
   begin
      if Name'Length = 0 then
         return False;
      end if;

      for Existing of Result.Items loop
         if Existing.Kind = Editor.Outline.Outline_Field
           and then Existing.Line = Object.Line
           and then To_String (Existing.Label) = "field " & Name
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Field_Row_For_Object;

   procedure Remove_Object_Field_Duplicates
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in reverse Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item : constant Editor.Outline.Outline_Item :=
              Result.Items.Element (I);
         begin
            if Item.Kind = Editor.Outline.Outline_Object
              and then Has_Field_Row_For_Object (Result, Item)
            then
               Result.Items.Delete (I);
            end if;
         end;
      end loop;
   end Remove_Object_Field_Duplicates;

   procedure Normalize_Generic_Depths_From_Ranges
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item  : Editor.Outline.Outline_Item := Result.Items.Element (I);
            Label : constant String := To_String (Item.Label);
         begin
            if Starts_With (Label, "formal ") and then Item.Depth /= 0 then
               Item.Depth := 0;
               Result.Items.Replace_Element (I, Item);
            end if;
         end;
      end loop;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item       : Editor.Outline.Outline_Item := Result.Items.Element (I);
            Label      : constant String := To_String (Item.Label);
            Old_Depth  : constant Natural := Item.Depth;
            Start_Line : constant Natural := Editor.Outline_Extractor.Detail_Parsing.Detail_Start_Line
              (To_String (Item.Detail));
            End_Line   : constant Natural := Editor.Outline_Extractor.Detail_Parsing.Detail_End_Line
              (To_String (Item.Detail));
         begin
            if Starts_With (Label, "generic ")
              and then Old_Depth > 0
            then
               Item.Depth := 0;
               Result.Items.Replace_Element (I, Item);

               if End_Line > Start_Line then
                  for J in Result.Items.First_Index .. Result.Items.Last_Index loop
                     if J /= I then
                        declare
                           Child : Editor.Outline.Outline_Item :=
                             Result.Items.Element (J);
                        begin
                           if Child.Line > Start_Line
                             and then Child.Line <= End_Line
                             and then Child.Depth >= Old_Depth
                           then
                              Child.Depth := Child.Depth - Old_Depth;
                              Result.Items.Replace_Element (J, Child);
                           end if;
                        end;
                     end if;
                  end loop;
               end if;
            end if;
         end;
      end loop;
   end Normalize_Generic_Depths_From_Ranges;

   procedure Normalize_Ranged_Child_Depths
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Parent     : constant Editor.Outline.Outline_Item :=
              Result.Items.Element (I);
            Start_Line : constant Natural :=
              Editor.Outline_Extractor.Detail_Parsing.Detail_Start_Line
                (To_String (Parent.Detail));
            End_Line   : constant Natural :=
              Editor.Outline_Extractor.Detail_Parsing.Detail_End_Line
                (To_String (Parent.Detail));
            Form       : constant String :=
              Editor.Outline_Extractor.Detail_Parsing.Primary_Detail_Form
                (To_String (Parent.Detail));
            Has_Range  : constant Boolean :=
              Parent.Kind in Editor.Outline.Outline_Package_Body
                 | Editor.Outline.Outline_Task
                 | Editor.Outline.Outline_Protected
              or else (Parent.Kind = Editor.Outline.Outline_Package
                       and then Form = "spec")
              or else ((Parent.Kind = Editor.Outline.Outline_Procedure
                        or else Parent.Kind = Editor.Outline.Outline_Function)
                       and then Form = "body")
              or else (Parent.Kind = Editor.Outline.Outline_Type
                       and then (Form = "record" or else Form = "variant"));
         begin
            if End_Line > Start_Line and then Has_Range then
               for J in Result.Items.First_Index .. Result.Items.Last_Index loop
                  if J /= I then
                     declare
                        Child : Editor.Outline.Outline_Item :=
                          Result.Items.Element (J);
                     begin
                        if Child.Line > Start_Line
                          and then Child.Line < End_Line
                          and then Child.Depth <= Parent.Depth
                        then
                           Child.Depth := Parent.Depth + 1;
                           Result.Items.Replace_Element (J, Child);
                        end if;
                     end;
                  end if;
               end loop;
            end if;
         end;
      end loop;
   end Normalize_Ranged_Child_Depths;

   procedure Normalize_Depths_To_Nearest_Range
     (Result : in out Extraction_Result)
   is
      function Has_Structure_Range
        (Item : Editor.Outline.Outline_Item) return Boolean
      is
         Form : constant String :=
           Editor.Outline_Extractor.Detail_Parsing.Primary_Detail_Form
             (To_String (Item.Detail));
      begin
         return Item.Kind in Editor.Outline.Outline_Package_Body
              | Editor.Outline.Outline_Task
              | Editor.Outline.Outline_Protected
           or else (Item.Kind = Editor.Outline.Outline_Package
                    and then Form = "spec")
           or else ((Item.Kind = Editor.Outline.Outline_Procedure
                     or else Item.Kind = Editor.Outline.Outline_Function)
                    and then Form = "body")
           or else (Item.Kind = Editor.Outline.Outline_Type
                    and then (Form = "record" or else Form = "variant"));
      end Has_Structure_Range;
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Child          : Editor.Outline.Outline_Item := Result.Items.Element (I);
            Best_Parent    : Natural := Result.Items.First_Index;
            Best_Span      : Natural := Natural'Last;
            Has_Parent     : Boolean := False;
         begin
            for J in Result.Items.First_Index .. Result.Items.Last_Index loop
               if J /= I then
                  declare
                     Parent     : constant Editor.Outline.Outline_Item :=
                       Result.Items.Element (J);
                     Start_Line : constant Natural :=
                       Editor.Outline_Extractor.Detail_Parsing.Detail_Start_Line
                         (To_String (Parent.Detail));
                     End_Line   : constant Natural :=
                       Editor.Outline_Extractor.Detail_Parsing.Detail_End_Line
                         (To_String (Parent.Detail));
                     Span       : constant Natural :=
                       (if End_Line > Start_Line then End_Line - Start_Line else 0);
                  begin
                     if Has_Structure_Range (Parent)
                       and then (Start_Line < Child.Line
                                 or else (Start_Line = Child.Line
                                          and then Child.Kind in
                                            Editor.Outline.Outline_Discriminant
                                              | Editor.Outline.Outline_Enum_Literal))
                       and then Child.Line < End_Line
                       and then Span > 0
                       and then Span < Best_Span
                     then
                        Best_Parent := J;
                        Best_Span := Span;
                        Has_Parent := True;
                     end if;
                  end;
               end if;
            end loop;

            if Has_Parent then
               declare
                  Parent : constant Editor.Outline.Outline_Item :=
                    Result.Items.Element (Best_Parent);
                  Desired : constant Natural := Parent.Depth + 1;
               begin
                  if Child.Depth /= Desired then
                     Child.Depth := Desired;
                     Result.Items.Replace_Element (I, Child);
                  end if;
               end;
            end if;
         end;
      end loop;
   end Normalize_Depths_To_Nearest_Range;

   procedure Normalize_Same_Line_Enum_Literal_Depths
     (Result : in out Extraction_Result)
   is
   begin
      if Result.Items.Is_Empty then
         return;
      end if;

      for I in Result.Items.First_Index .. Result.Items.Last_Index loop
         declare
            Item : Editor.Outline.Outline_Item := Result.Items.Element (I);
         begin
            if Item.Kind = Editor.Outline.Outline_Enum_Literal then
               for J in reverse Result.Items.First_Index .. I loop
                  declare
                     Parent : constant Editor.Outline.Outline_Item :=
                       Result.Items.Element (J);
                  begin
                     if Parent.Kind = Editor.Outline.Outline_Type
                       and then Parent.Line = Item.Line
                       and then Starts_With (To_String (Parent.Label), "enum type ")
                     then
                        Item.Depth := Parent.Depth + 1;
                        Result.Items.Replace_Element (I, Item);
                        exit;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;
   end Normalize_Same_Line_Enum_Literal_Depths;

end Editor.Outline_Extractor.Range_Analysis;
