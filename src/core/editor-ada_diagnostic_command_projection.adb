with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Diagnostic_Command_Projection is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 191) + B + 223) mod 1_000_000_007;
   end Mix;

   function Kind_For
     (Route_Kind : Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Kind)
      return Diagnostic_Command_Kind is
   begin
      case Route_Kind is
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Navigate =>
            return Diagnostic_Command_Navigate_To_Diagnostic;
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Explain =>
            return Diagnostic_Command_Explain_Diagnostic;
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Review_Expression =>
            return Diagnostic_Command_Review_Expression;
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Review_Overload_Ranking =>
            return Diagnostic_Command_Review_Overload_Ranking;
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Review_Generic =>
            return Diagnostic_Command_Review_Generic;
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Review_Cross_Unit =>
            return Diagnostic_Command_Review_Cross_Unit;
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Review_Representation =>
            return Diagnostic_Command_Review_Representation;
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_None =>
            return Diagnostic_Command_None;
      end case;
   end Kind_For;

   function Name_For (Kind : Diagnostic_Command_Kind) return String is
   begin
      case Kind is
         when Diagnostic_Command_Navigate_To_Diagnostic =>
            return "ada.diagnostic.navigate";
         when Diagnostic_Command_Explain_Diagnostic =>
            return "ada.diagnostic.explain";
         when Diagnostic_Command_Review_Expression =>
            return "ada.diagnostic.review-expression";
         when Diagnostic_Command_Review_Overload_Ranking =>
            return "ada.diagnostic.review-overload-ranking";
         when Diagnostic_Command_Review_Generic =>
            return "ada.diagnostic.review-generic";
         when Diagnostic_Command_Review_Cross_Unit =>
            return "ada.diagnostic.review-cross-unit";
         when Diagnostic_Command_Review_Representation =>
            return "ada.diagnostic.review-representation";
         when Diagnostic_Command_None =>
            return "ada.diagnostic.none";
      end case;
   end Name_For;

   function Availability_For
     (Status : Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Target_Status)
      return Diagnostic_Command_Availability is
   begin
      case Status is
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Target_Complete =>
            return Diagnostic_Command_Available;
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Target_Status_Only =>
            return Diagnostic_Command_Status_Only;
         when Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Target_Incomplete =>
            return Diagnostic_Command_Incomplete_Target;
         when others =>
            return Diagnostic_Command_Missing_Target;
      end case;
   end Availability_For;

   function Descriptor_Fingerprint
     (Descriptor : Diagnostic_Command_Descriptor) return Natural
   is
      H : Natural := Natural (Descriptor.Id);
   begin
      H := Mix (H, Natural (Descriptor.Index_Id) + 1);
      H := Mix (H, Descriptor.Feed_Index + 1);
      H := Mix (H, Descriptor.Diagnostic.Fingerprint + 1);
      H := Mix (H, Natural (Descriptor.Route_Id) + 1);
      H := Mix (H, Diagnostic_Command_Kind'Pos (Descriptor.Command_Kind) + 1);
      H := Mix
        (H, Diagnostic_Command_Availability'Pos (Descriptor.Availability) + 1);
      H := Mix (H, Descriptor.Start_Line);
      H := Mix (H, Descriptor.Start_Column);
      H := Mix (H, Descriptor.Route_Fingerprint + 1);
      return H;
   end Descriptor_Fingerprint;

   procedure Increment_Kind
     (Model : in out Diagnostic_Command_Projection_Model;
      Kind  : Diagnostic_Command_Kind) is
   begin
      case Kind is
         when Diagnostic_Command_Navigate_To_Diagnostic =>
            Model.Navigate_Total := Model.Navigate_Total + 1;
         when Diagnostic_Command_Explain_Diagnostic =>
            Model.Explain_Total := Model.Explain_Total + 1;
         when Diagnostic_Command_Review_Expression =>
            Model.Expression_Total := Model.Expression_Total + 1;
         when Diagnostic_Command_Review_Overload_Ranking =>
            Model.Overload_Ranking_Total := Model.Overload_Ranking_Total + 1;
         when Diagnostic_Command_Review_Generic =>
            Model.Generic_Total := Model.Generic_Total + 1;
         when Diagnostic_Command_Review_Cross_Unit =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Diagnostic_Command_Review_Representation =>
            Model.Representation_Total := Model.Representation_Total + 1;
         when Diagnostic_Command_None =>
            null;
      end case;
   end Increment_Kind;

   procedure Increment_Availability
     (Model        : in out Diagnostic_Command_Projection_Model;
      Availability : Diagnostic_Command_Availability) is
   begin
      case Availability is
         when Diagnostic_Command_Available =>
            Model.Available_Total := Model.Available_Total + 1;
         when Diagnostic_Command_Missing_Target =>
            Model.Missing_Total := Model.Missing_Total + 1;
         when Diagnostic_Command_Incomplete_Target =>
            Model.Incomplete_Total := Model.Incomplete_Total + 1;
         when Diagnostic_Command_Status_Only =>
            Model.Status_Only_Total := Model.Status_Only_Total + 1;
         when Diagnostic_Command_Rejected_Stale =>
            Model.Rejected_Total := Model.Rejected_Total + 1;
      end case;
   end Increment_Availability;

   procedure Clear (Model : in out Diagnostic_Command_Projection_Model) is
   begin
      Model.Descriptors.Clear;
      Model.Model_Status := Diagnostic_Command_Projection_Current;
      Model.Available_Total := 0;
      Model.Missing_Total := 0;
      Model.Incomplete_Total := 0;
      Model.Status_Only_Total := 0;
      Model.Rejected_Total := 0;
      Model.Editable_Total := 0;
      Model.Navigate_Total := 0;
      Model.Explain_Total := 0;
      Model.Expression_Total := 0;
      Model.Overload_Ranking_Total := 0;
      Model.Generic_Total := 0;
      Model.Cross_Unit_Total := 0;
      Model.Representation_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Routes : Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Router_Model)
      return Diagnostic_Command_Projection_Model
   is
      Model : Diagnostic_Command_Projection_Model;
   begin
      if Editor.Ada_Diagnostic_Action_Router.Rejected_Stale (Routes) then
         Model.Model_Status := Diagnostic_Command_Projection_Rejected_Stale;
         Model.Rejected_Total := Editor.Ada_Diagnostic_Action_Router.Rejected_Route_Count (Routes);
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Diagnostic_Action_Router.Fingerprint (Routes),
                Model.Rejected_Total + 1);
         return Model;
      end if;

      Model.Result_Fingerprint := Editor.Ada_Diagnostic_Action_Router.Fingerprint (Routes);

      for I in 1 .. Editor.Ada_Diagnostic_Action_Router.Route_Count (Routes) loop
         declare
            Route : constant Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route :=
              Editor.Ada_Diagnostic_Action_Router.Route_At (Routes, I);
            Descriptor : Diagnostic_Command_Descriptor;
         begin
            Descriptor.Id := Diagnostic_Command_Descriptor_Id (I);
            Descriptor.Index_Id := Route.Index_Id;
            Descriptor.Feed_Index := Route.Feed_Index;
            Descriptor.Diagnostic := Route.Diagnostic;
            Descriptor.Severity := Route.Severity;
            Descriptor.Source := Route.Source;
            Descriptor.Token := Route.Token;
            Descriptor.Node := Route.Node;
            Descriptor.Route_Id := Route.Id;
            Descriptor.Route_Kind := Route.Route_Kind;
            Descriptor.Command_Kind := Kind_For (Route.Route_Kind);
            Descriptor.Availability := Availability_For (Route.Target_Status);
            Descriptor.Command_Name := To_Unbounded_String (Name_For (Descriptor.Command_Kind));
            Descriptor.Display_Label := Route.Label;
            Descriptor.Detail := Route.Detail;
            Descriptor.Has_Edit := Route.Has_Edit;
            Descriptor.Start_Line := Route.Start_Line;
            Descriptor.Start_Column := Route.Start_Column;
            Descriptor.End_Line := Route.End_Line;
            Descriptor.End_Column := Route.End_Column;
            Descriptor.Route_Fingerprint := Route.Fingerprint;
            Descriptor.Fingerprint := Descriptor_Fingerprint (Descriptor);

            Model.Descriptors.Append (Descriptor);
            if Descriptor.Has_Edit then
               Model.Editable_Total := Model.Editable_Total + 1;
            end if;
            Increment_Kind (Model, Descriptor.Command_Kind);
            Increment_Availability (Model, Descriptor.Availability);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Descriptor.Fingerprint + 1);
         end;
      end loop;

      return Model;
   end Build;

   function Status
     (Model : Diagnostic_Command_Projection_Model)
      return Diagnostic_Command_Projection_Status is
   begin
      return Model.Model_Status;
   end Status;

   function Current (Model : Diagnostic_Command_Projection_Model) return Boolean is
   begin
      return Model.Model_Status = Diagnostic_Command_Projection_Current;
   end Current;

   function Rejected_Stale (Model : Diagnostic_Command_Projection_Model) return Boolean is
   begin
      return Model.Model_Status = Diagnostic_Command_Projection_Rejected_Stale;
   end Rejected_Stale;

   function Descriptor_Count (Model : Diagnostic_Command_Projection_Model) return Natural is
   begin
      return Natural (Model.Descriptors.Length);
   end Descriptor_Count;

   function Descriptor_At
     (Model : Diagnostic_Command_Projection_Model;
      Index : Positive) return Diagnostic_Command_Descriptor is
   begin
      if Index > Natural (Model.Descriptors.Length) then
         return (others => <>);
      end if;
      return Model.Descriptors.Element (Index);
   end Descriptor_At;

   function Available_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural is
   begin
      return Model.Available_Total;
   end Available_Command_Count;

   function Missing_Target_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural is
   begin
      return Model.Missing_Total;
   end Missing_Target_Command_Count;

   function Incomplete_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural is
   begin
      return Model.Incomplete_Total;
   end Incomplete_Command_Count;

   function Status_Only_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural is
   begin
      return Model.Status_Only_Total;
   end Status_Only_Command_Count;

   function Rejected_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Command_Count;

   function Editable_Command_Count
     (Model : Diagnostic_Command_Projection_Model) return Natural is
   begin
      return Model.Editable_Total;
   end Editable_Command_Count;

   function Count_Kind
     (Model : Diagnostic_Command_Projection_Model;
      Kind  : Diagnostic_Command_Kind) return Natural is
   begin
      case Kind is
         when Diagnostic_Command_Navigate_To_Diagnostic => return Model.Navigate_Total;
         when Diagnostic_Command_Explain_Diagnostic => return Model.Explain_Total;
         when Diagnostic_Command_Review_Expression => return Model.Expression_Total;
         when Diagnostic_Command_Review_Overload_Ranking => return Model.Overload_Ranking_Total;
         when Diagnostic_Command_Review_Generic => return Model.Generic_Total;
         when Diagnostic_Command_Review_Cross_Unit => return Model.Cross_Unit_Total;
         when Diagnostic_Command_Review_Representation => return Model.Representation_Total;
         when Diagnostic_Command_None => return 0;
      end case;
   end Count_Kind;

   function Count_Availability
     (Model        : Diagnostic_Command_Projection_Model;
      Availability : Diagnostic_Command_Availability) return Natural is
   begin
      case Availability is
         when Diagnostic_Command_Available => return Model.Available_Total;
         when Diagnostic_Command_Missing_Target => return Model.Missing_Total;
         when Diagnostic_Command_Incomplete_Target => return Model.Incomplete_Total;
         when Diagnostic_Command_Status_Only => return Model.Status_Only_Total;
         when Diagnostic_Command_Rejected_Stale => return Model.Rejected_Total;
      end case;
   end Count_Availability;

   function First_For_Diagnostic
     (Model    : Diagnostic_Command_Projection_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Command_Descriptor is
   begin
      for I in 1 .. Natural (Model.Descriptors.Length) loop
         if Model.Descriptors.Element (I).Index_Id = Index_Id then
            return Model.Descriptors.Element (I);
         end if;
      end loop;
      return (others => <>);
   end First_For_Diagnostic;

   function Descriptors_For_Diagnostic
     (Model    : Diagnostic_Command_Projection_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Command_Descriptor_Set
   is
      Results : Diagnostic_Command_Descriptor_Set;
   begin
      for I in 1 .. Natural (Model.Descriptors.Length) loop
         declare
            Descriptor : constant Diagnostic_Command_Descriptor := Model.Descriptors.Element (I);
         begin
            if Descriptor.Index_Id = Index_Id then
               Results.Descriptors.Append (Descriptor);
               Results.Fingerprint := Mix (Results.Fingerprint, Descriptor.Fingerprint + 1);
            end if;
         end;
      end loop;
      return Results;
   end Descriptors_For_Diagnostic;

   function Descriptor_Set_Count (Descriptors : Diagnostic_Command_Descriptor_Set) return Natural is
   begin
      return Natural (Descriptors.Descriptors.Length);
   end Descriptor_Set_Count;

   function Descriptor_Set_At
     (Descriptors : Diagnostic_Command_Descriptor_Set;
      Index       : Positive) return Diagnostic_Command_Descriptor is
   begin
      if Index > Natural (Descriptors.Descriptors.Length) then
         return (others => <>);
      end if;
      return Descriptors.Descriptors.Element (Index);
   end Descriptor_Set_At;

   function Has_Descriptor (Descriptor : Diagnostic_Command_Descriptor) return Boolean is
   begin
      return Descriptor.Id /= No_Diagnostic_Command_Descriptor;
   end Has_Descriptor;

   function Fingerprint (Model : Diagnostic_Command_Projection_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Diagnostic_Command_Projection;
