package org.xrstudio.xmpp.flutter_xmpp.listner;

import android.content.Context;
import android.util.Log;

import org.jivesoftware.smack.StanzaListener;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.packet.Stanza;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

public class MessageListener implements StanzaListener {

    private static Context mApplicationContext;

    public MessageListener(Context context) {
        mApplicationContext = context;
    }

    @Override
    public void processStanza(Stanza packet) {

        Message message = (Message) packet;
        if (message.getType() == Message.Type.error) {
            Log.d("XMPP_MUC", "message error id=" + message.getStanzaId() + " from=" + message.getFrom() + " error=" + message.getError() + " t=" + System.currentTimeMillis());
        }
        Utils.broadcastMessageToFlutter(mApplicationContext, message);
    }
}
