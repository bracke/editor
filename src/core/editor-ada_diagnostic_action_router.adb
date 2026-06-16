with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Diagnostic_Action_Router is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 181) + B + 211) mod 1_000_000_007;
   end Mix;

   function Route_Kind_For
     (Action : Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Action_Kind)
      return Diagnostic_Action_Route_Kind is
   begin
      case Action is
         when Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Navigate_To_Diagnostic =>
            return Diagnostic_Action_Route_Navigate;
         when Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Show_Explanation =>
            return Diagnostic_Action_Route_Explain;
         when Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Review_Expression_Type =>
            return Diagnostic_Action_Route_Review_Expression;
         when Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Review_Overload_Ranking =>
            return Diagnostic_Action_Route_Review_Overload_Ranking;
         when Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Review_Generic_Actual =>
            return Diagnostic_Action_Route_Review_Generic;
         when Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Review_Cross_Unit_Dependency =>
            return Diagnostic_Action_Route_Review_Cross_Unit;
         when Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Review_Representation_Item =>
            return Diagnostic_Action_Route_Review_Representation;
         when others =>
            return Diagnostic_Action_Route_None;
      end case;
   end Route_Kind_For;

   function Route_Fingerprint (Route : Diagnostic_Action_Route) return Natural is
      H : Natural := Natural (Route.Id);
   begin
      H := Mix (H, Natural (Route.Index_Id) + 1);
      H := Mix (H, Route.Feed_Index + 1);
      H := Mix (H, Route.Diagnostic.Fingerprint + 1);
      H := Mix (H, Natural (Route.Quick_Fix_Id) + 1);
      H := Mix (H, Natural (Route.Navigation_Target) + 1);
      H := Mix (H, Natural (Route.Panel_Row) + 1);
      H := Mix (H, Natural (Route.Provenance_Item) + 1);
      H := Mix (H, Route.Quick_Fix_Fingerprint + 1);
      H := Mix (H, Route.Navigation_Fingerprint + 1);
      H := Mix (H, Route.Panel_Fingerprint + 1);
      H := Mix (H, Route.Provenance_Fingerprint + 1);
      H := Mix (H, Route.Status_Fingerprint + 1);
      H := Mix (H, Route.Start_Line);
      H := Mix (H, Route.Start_Column);
      return H;
   end Route_Fingerprint;

   function Find_Navigation
     (Navigation : Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model;
      Index_Id   : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target is
   begin
      for I in 1 .. Editor.Ada_Diagnostic_Navigation.Navigation_Target_Count (Navigation) loop
         declare
            Target : constant Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target :=
              Editor.Ada_Diagnostic_Navigation.Target_At (Navigation, I);
         begin
            if Target.Index_Id = Index_Id then
               return Target;
            end if;
         end;
      end loop;
      return (others => <>);
   end Find_Navigation;

   function Find_Panel_Row
     (Panel    : Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Row is
   begin
      for I in 1 .. Editor.Ada_Diagnostic_Panel_Projection.Row_Count (Panel) loop
         declare
            Row : constant Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Row :=
              Editor.Ada_Diagnostic_Panel_Projection.Row_At (Panel, I);
         begin
            if Row.Index_Id = Index_Id then
               return Row;
            end if;
         end;
      end loop;
      return (others => <>);
   end Find_Panel_Row;

   function Status_Target_Matches
     (Status_Line : Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model;
      Index_Id    : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Boolean is
      Target : constant Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Target :=
        Editor.Ada_Diagnostic_Status_Line.Nearest_Diagnostic (Status_Line);
   begin
      return Editor.Ada_Diagnostic_Status_Line.Has_Target (Target)
        and then Target.Index_Id = Index_Id;
   end Status_Target_Matches;

   function Target_Status_For
     (Has_Navigation : Boolean;
      Has_Panel      : Boolean;
      Has_Provenance : Boolean;
      Has_Status     : Boolean;
      Kind           : Diagnostic_Action_Route_Kind)
      return Diagnostic_Action_Route_Target_Status is
   begin
      if Has_Navigation and then Has_Panel and then
        (Has_Provenance or else Kind = Diagnostic_Action_Route_Navigate)
      then
         return Diagnostic_Action_Route_Target_Complete;
      elsif not Has_Navigation then
         return Diagnostic_Action_Route_Target_No_Navigation;
      elsif not Has_Panel then
         return Diagnostic_Action_Route_Target_No_Panel_Row;
      elsif not Has_Provenance and then Kind /= Diagnostic_Action_Route_Navigate then
         return Diagnostic_Action_Route_Target_No_Provenance;
      elsif Has_Status then
         return Diagnostic_Action_Route_Target_Status_Only;
      else
         return Diagnostic_Action_Route_Target_Incomplete;
      end if;
   end Target_Status_For;

   procedure Increment_Kind
     (Model : in out Diagnostic_Action_Router_Model;
      Kind  : Diagnostic_Action_Route_Kind) is
   begin
      case Kind is
         when Diagnostic_Action_Route_Navigate =>
            Model.Navigate_Total := Model.Navigate_Total + 1;
         when Diagnostic_Action_Route_Explain =>
            Model.Explain_Total := Model.Explain_Total + 1;
         when Diagnostic_Action_Route_Review_Expression =>
            Model.Expression_Total := Model.Expression_Total + 1;
         when Diagnostic_Action_Route_Review_Overload_Ranking =>
            Model.Overload_Ranking_Total := Model.Overload_Ranking_Total + 1;
         when Diagnostic_Action_Route_Review_Generic =>
            Model.Generic_Total := Model.Generic_Total + 1;
         when Diagnostic_Action_Route_Review_Cross_Unit =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Diagnostic_Action_Route_Review_Representation =>
            Model.Representation_Total := Model.Representation_Total + 1;
         when Diagnostic_Action_Route_None =>
            null;
      end case;
   end Increment_Kind;

   procedure Increment_Target_Status
     (Model  : in out Diagnostic_Action_Router_Model;
      Status : Diagnostic_Action_Route_Target_Status) is
   begin
      case Status is
         when Diagnostic_Action_Route_Target_Complete =>
            Model.Complete_Total := Model.Complete_Total + 1;
         when Diagnostic_Action_Route_Target_No_Navigation =>
            Model.No_Navigation_Total := Model.No_Navigation_Total + 1;
         when Diagnostic_Action_Route_Target_No_Panel_Row =>
            Model.No_Panel_Total := Model.No_Panel_Total + 1;
         when Diagnostic_Action_Route_Target_No_Provenance =>
            Model.No_Provenance_Total := Model.No_Provenance_Total + 1;
         when Diagnostic_Action_Route_Target_Status_Only =>
            Model.Status_Only_Total := Model.Status_Only_Total + 1;
         when Diagnostic_Action_Route_Target_Incomplete =>
            Model.Incomplete_Total := Model.Incomplete_Total + 1;
      end case;
   end Increment_Target_Status;

   procedure Clear (Model : in out Diagnostic_Action_Router_Model) is
   begin
      Model.Routes.Clear;
      Model.Router_Status := Diagnostic_Action_Router_Current;
      Model.Complete_Total := 0;
      Model.Rejected_Total := 0;
      Model.Editable_Total := 0;
      Model.Navigate_Total := 0;
      Model.Explain_Total := 0;
      Model.Expression_Total := 0;
      Model.Overload_Ranking_Total := 0;
      Model.Generic_Total := 0;
      Model.Cross_Unit_Total := 0;
      Model.Representation_Total := 0;
      Model.No_Navigation_Total := 0;
      Model.No_Panel_Total := 0;
      Model.No_Provenance_Total := 0;
      Model.Status_Only_Total := 0;
      Model.Incomplete_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Quick_Fixes : Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model;
      Navigation  : Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model;
      Panel       : Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model;
      Provenance  : Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model;
      Status_Line : Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model)
      return Diagnostic_Action_Router_Model
   is
      Model : Diagnostic_Action_Router_Model;
   begin
      if Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Rejected_Stale (Quick_Fixes)
        or else Editor.Ada_Diagnostic_Navigation.Rejected_Stale (Navigation)
        or else Editor.Ada_Diagnostic_Panel_Projection.Rejected_Stale (Panel)
        or else Editor.Ada_Diagnostic_Provenance.Rejected_Stale (Provenance)
        or else Editor.Ada_Diagnostic_Status_Line.Rejected_Stale (Status_Line)
      then
         Model.Router_Status := Diagnostic_Action_Router_Rejected_Stale;
         Model.Rejected_Total :=
           Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Rejected_Candidate_Count (Quick_Fixes)
           + Editor.Ada_Diagnostic_Navigation.Rejected_Target_Count (Navigation)
           + Editor.Ada_Diagnostic_Panel_Projection.Rejected_Row_Count (Panel)
           + Editor.Ada_Diagnostic_Provenance.Rejected_Item_Count (Provenance)
           + Editor.Ada_Diagnostic_Status_Line.Rejected_Diagnostic_Count (Status_Line);
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Fingerprint (Quick_Fixes),
                Model.Rejected_Total + 1);
         return Model;
      end if;

      Model.Result_Fingerprint :=
        Mix (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Fingerprint (Quick_Fixes),
             Editor.Ada_Diagnostic_Navigation.Fingerprint (Navigation) + 1);
      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Diagnostic_Panel_Projection.Fingerprint (Panel) + 1);
      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Diagnostic_Provenance.Fingerprint (Provenance) + 1);
      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Editor.Ada_Diagnostic_Status_Line.Fingerprint (Status_Line) + 1);

      for I in 1 .. Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Candidate_Count (Quick_Fixes) loop
         declare
            Candidate : constant Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Candidate :=
              Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Candidate_At (Quick_Fixes, I);
            Nav : constant Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target :=
              Find_Navigation (Navigation, Candidate.Index_Id);
            Row : constant Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Row :=
              Find_Panel_Row (Panel, Candidate.Index_Id);
            Prov : constant Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Item :=
              Editor.Ada_Diagnostic_Provenance.First_For_Diagnostic
                (Provenance, Candidate.Index_Id);
            Has_Nav : constant Boolean :=
              Editor.Ada_Diagnostic_Navigation.Has_Target (Nav);
            Has_Row : constant Boolean :=
              Editor.Ada_Diagnostic_Panel_Projection.Has_Row (Row);
            Has_Prov : constant Boolean :=
              Editor.Ada_Diagnostic_Provenance.Has_Item (Prov);
            Has_Status : constant Boolean :=
              Status_Target_Matches (Status_Line, Candidate.Index_Id);
            Route : Diagnostic_Action_Route;
         begin
            Route.Id := Diagnostic_Action_Route_Id (I);
            Route.Index_Id := Candidate.Index_Id;
            Route.Feed_Index := Candidate.Feed_Index;
            Route.Diagnostic := Candidate.Diagnostic;
            Route.Severity := Candidate.Severity;
            Route.Source := Candidate.Source;
            Route.Token := Candidate.Token;
            Route.Node := Candidate.Node;
            Route.Quick_Fix_Id := Candidate.Id;
            Route.Quick_Fix_Action := Candidate.Action;
            Route.Route_Kind := Route_Kind_For (Candidate.Action);
            Route.Navigation_Target := (if Has_Nav then Nav.Id else Editor.Ada_Diagnostic_Navigation.No_Diagnostic_Navigation_Target);
            Route.Panel_Row := (if Has_Row then Row.Id else Editor.Ada_Diagnostic_Panel_Projection.No_Diagnostic_Panel_Row);
            Route.Provenance_Item := (if Has_Prov then Prov.Id else Editor.Ada_Diagnostic_Provenance.No_Diagnostic_Provenance);
            Route.Status_Target_Available := Has_Status;
            Route.Has_Edit := Candidate.Has_Edit;
            Route.Label := Candidate.Label;
            Route.Detail := Candidate.Detail;
            Route.Start_Line := Candidate.Start_Line;
            Route.Start_Column := Candidate.Start_Column;
            Route.End_Line := Candidate.End_Line;
            Route.End_Column := Candidate.End_Column;
            Route.Quick_Fix_Fingerprint := Candidate.Fingerprint;
            Route.Navigation_Fingerprint := (if Has_Nav then Nav.Fingerprint else 0);
            Route.Panel_Fingerprint := (if Has_Row then Row.Fingerprint else 0);
            Route.Provenance_Fingerprint := (if Has_Prov then Prov.Fingerprint else 0);
            Route.Status_Fingerprint := Editor.Ada_Diagnostic_Status_Line.Fingerprint (Status_Line);
            Route.Target_Status :=
              Target_Status_For (Has_Nav, Has_Row, Has_Prov, Has_Status, Route.Route_Kind);
            Route.Fingerprint := Route_Fingerprint (Route);

            Model.Routes.Append (Route);
            if Route.Has_Edit then
               Model.Editable_Total := Model.Editable_Total + 1;
            end if;
            Increment_Kind (Model, Route.Route_Kind);
            Increment_Target_Status (Model, Route.Target_Status);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Route.Fingerprint + 1);
         end;
      end loop;

      return Model;
   end Build;

   function Status
     (Model : Diagnostic_Action_Router_Model) return Diagnostic_Action_Router_Status is
   begin
      return Model.Router_Status;
   end Status;

   function Current (Model : Diagnostic_Action_Router_Model) return Boolean is
   begin
      return Model.Router_Status = Diagnostic_Action_Router_Current;
   end Current;

   function Rejected_Stale (Model : Diagnostic_Action_Router_Model) return Boolean is
   begin
      return Model.Router_Status = Diagnostic_Action_Router_Rejected_Stale;
   end Rejected_Stale;

   function Route_Count (Model : Diagnostic_Action_Router_Model) return Natural is
   begin
      return Natural (Model.Routes.Length);
   end Route_Count;

   function Route_At
     (Model : Diagnostic_Action_Router_Model;
      Index : Positive) return Diagnostic_Action_Route is
   begin
      if Index > Natural (Model.Routes.Length) then
         return (others => <>);
      end if;
      return Model.Routes.Element (Index);
   end Route_At;

   function Complete_Route_Count (Model : Diagnostic_Action_Router_Model) return Natural is
   begin
      return Model.Complete_Total;
   end Complete_Route_Count;

   function Navigate_Route_Count (Model : Diagnostic_Action_Router_Model) return Natural is
   begin
      return Model.Navigate_Total;
   end Navigate_Route_Count;

   function Explain_Route_Count (Model : Diagnostic_Action_Router_Model) return Natural is
   begin
      return Model.Explain_Total;
   end Explain_Route_Count;

   function Overload_Ranking_Route_Count
     (Model : Diagnostic_Action_Router_Model) return Natural is
   begin
      return Model.Overload_Ranking_Total;
   end Overload_Ranking_Route_Count;

   function Rejected_Route_Count (Model : Diagnostic_Action_Router_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Route_Count;

   function Editable_Route_Count (Model : Diagnostic_Action_Router_Model) return Natural is
   begin
      return Model.Editable_Total;
   end Editable_Route_Count;

   function Count_Kind
     (Model : Diagnostic_Action_Router_Model;
      Kind  : Diagnostic_Action_Route_Kind) return Natural is
   begin
      case Kind is
         when Diagnostic_Action_Route_Navigate => return Model.Navigate_Total;
         when Diagnostic_Action_Route_Explain => return Model.Explain_Total;
         when Diagnostic_Action_Route_Review_Expression => return Model.Expression_Total;
         when Diagnostic_Action_Route_Review_Overload_Ranking => return Model.Overload_Ranking_Total;
         when Diagnostic_Action_Route_Review_Generic => return Model.Generic_Total;
         when Diagnostic_Action_Route_Review_Cross_Unit => return Model.Cross_Unit_Total;
         when Diagnostic_Action_Route_Review_Representation => return Model.Representation_Total;
         when Diagnostic_Action_Route_None => return 0;
      end case;
   end Count_Kind;

   function Count_Target_Status
     (Model  : Diagnostic_Action_Router_Model;
      Status : Diagnostic_Action_Route_Target_Status) return Natural is
   begin
      case Status is
         when Diagnostic_Action_Route_Target_Complete => return Model.Complete_Total;
         when Diagnostic_Action_Route_Target_No_Navigation => return Model.No_Navigation_Total;
         when Diagnostic_Action_Route_Target_No_Panel_Row => return Model.No_Panel_Total;
         when Diagnostic_Action_Route_Target_No_Provenance => return Model.No_Provenance_Total;
         when Diagnostic_Action_Route_Target_Status_Only => return Model.Status_Only_Total;
         when Diagnostic_Action_Route_Target_Incomplete => return Model.Incomplete_Total;
      end case;
   end Count_Target_Status;

   function First_For_Diagnostic
     (Model    : Diagnostic_Action_Router_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Action_Route is
   begin
      for I in 1 .. Natural (Model.Routes.Length) loop
         if Model.Routes.Element (I).Index_Id = Index_Id then
            return Model.Routes.Element (I);
         end if;
      end loop;
      return (others => <>);
   end First_For_Diagnostic;

   function Routes_For_Diagnostic
     (Model    : Diagnostic_Action_Router_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Action_Route_Set
   is
      Results : Diagnostic_Action_Route_Set;
   begin
      for I in 1 .. Natural (Model.Routes.Length) loop
         declare
            Route : constant Diagnostic_Action_Route := Model.Routes.Element (I);
         begin
            if Route.Index_Id = Index_Id then
               Results.Routes.Append (Route);
               Results.Fingerprint := Mix (Results.Fingerprint, Route.Fingerprint + 1);
            end if;
         end;
      end loop;
      return Results;
   end Routes_For_Diagnostic;

   function Route_Set_Count (Routes : Diagnostic_Action_Route_Set) return Natural is
   begin
      return Natural (Routes.Routes.Length);
   end Route_Set_Count;

   function Route_Set_At
     (Routes : Diagnostic_Action_Route_Set;
      Index  : Positive) return Diagnostic_Action_Route is
   begin
      if Index > Natural (Routes.Routes.Length) then
         return (others => <>);
      end if;
      return Routes.Routes.Element (Index);
   end Route_Set_At;

   function Has_Route (Route : Diagnostic_Action_Route) return Boolean is
   begin
      return Route.Id /= No_Diagnostic_Action_Route;
   end Has_Route;

   function Fingerprint (Model : Diagnostic_Action_Router_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Diagnostic_Action_Router;
