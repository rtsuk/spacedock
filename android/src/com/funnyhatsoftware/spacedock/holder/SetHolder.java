package com.funnyhatsoftware.spacedock.holder;

import android.content.Context;
import android.content.res.Resources;
import android.view.View;
import android.widget.TextView;

import com.funnyhatsoftware.spacedock.R;
import com.funnyhatsoftware.spacedock.data.Set;
import com.funnyhatsoftware.spacedock.data.Universe;

import java.util.List;

public class SetHolder extends ItemHolder {
    public static final String TYPE_STRING = "Set";
    static ItemHolderFactory getFactory() {
        return new ItemHolderFactory(TYPE_STRING, R.layout.set_list_row, 0) {
            @Override
            public boolean usesFactions() {
                return false;
            }

            @Override
            public ItemHolder createHolder(View view) {
                return new SetHolder(view);
            }

            @Override
            public List<?> getItemsForFaction(String faction) {
                return Universe.getUniverse().getSets();
            }
        };
    }

    final TextView mTitle;

    private SetHolder(View view) {
        mTitle = (TextView) view.findViewById(R.id.setRowProductName);
    }

    @Override
    public void reinitialize(Resources res, Object item) {
        Set set = (Set) item;
        mTitle.setText(set.getProductName());
    }

    @Override
    public void navigateToDetails(Context context, Object item) {
        // TODO
    }
}
