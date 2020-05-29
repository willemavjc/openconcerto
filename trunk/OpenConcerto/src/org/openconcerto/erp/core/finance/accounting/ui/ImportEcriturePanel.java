/*
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
 *
 * Copyright 2011 OpenConcerto, by ILM Informatique. All rights reserved.
 *
 * The contents of this file are subject to the terms of the GNU General Public License Version 3
 * only ("GPL"). You may not use this file except in compliance with the License. You can obtain a
 * copy of the License at http://www.gnu.org/licenses/gpl-3.0.html See the License for the specific
 * language governing permissions and limitations under the License.
 *
 * When distributing the software, include this License Header Notice in each file.
 */

 package org.openconcerto.erp.core.finance.accounting.ui;

import org.openconcerto.erp.config.ComptaPropsConfiguration;
import org.openconcerto.erp.core.finance.accounting.element.ComptePCESQLElement;
import org.openconcerto.erp.generationEcritures.GenerationEcritures;
import org.openconcerto.erp.importer.ArrayTableModel;
import org.openconcerto.erp.importer.DataImporter;
import org.openconcerto.openoffice.ContentTypeVersioned;
import org.openconcerto.sql.model.ConnectionHandlerNoSetup;
import org.openconcerto.sql.model.DBRoot;
import org.openconcerto.sql.model.SQLBackgroundTableCache;
import org.openconcerto.sql.model.SQLDataSource;
import org.openconcerto.sql.model.SQLRow;
import org.openconcerto.sql.model.SQLRowListRSH;
import org.openconcerto.sql.model.SQLSelect;
import org.openconcerto.sql.utils.SQLUtils;
import org.openconcerto.ui.DefaultGridBagConstraints;
import org.openconcerto.ui.ReloadPanel;
import org.openconcerto.ui.SwingThreadUtils;
import org.openconcerto.utils.ExceptionHandler;
import org.openconcerto.utils.GestionDevise;

import java.awt.FileDialog;
import java.awt.Frame;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.sql.SQLException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;

public class ImportEcriturePanel extends JPanel {

    private final Map<String, Integer> mapJournal = new HashMap<>();
    private final Map<String, Integer> mapCompte = new HashMap<>();

    public ImportEcriturePanel() {
        super(new GridBagLayout());

        JLabel label = new JLabel("Import depuis un fichier CSV, XLS ou ODT.");
        JLabel label2 = new JLabel("Le fichier doit contenir les colonnes :");
        JLabel label3 = new JLabel(" - Date dd/MM/yyyy (dd/MM/yy pour le CSV)");
        JLabel label4 = new JLabel(" - Journal");
        JLabel label5 = new JLabel(" - N° de compte");
        JLabel label6 = new JLabel(" - Nom de la pièce");
        JLabel label7 = new JLabel(" - Libellé");
        JLabel label8 = new JLabel(" - Débit");
        JLabel label9 = new JLabel(" - Crédit");
        final JButton button = new JButton("Sélectionner le ficher");
        GridBagConstraints c = new DefaultGridBagConstraints();
        c.gridwidth = 2;
        this.add(label, c);
        c.gridy++;
        this.add(label2, c);
        c.gridy++;
        this.add(label3, c);
        c.gridy++;
        this.add(label4, c);
        c.gridy++;
        this.add(label5, c);
        c.gridy++;
        this.add(label6, c);
        c.gridy++;
        this.add(label7, c);
        c.gridy++;
        this.add(label8, c);
        c.gridy++;
        this.add(label9, c);
        c.gridy++;
        c.gridwidth = 1;
        c.weightx = 1;
        final ReloadPanel rlPanel = new ReloadPanel();
        c.anchor = GridBagConstraints.EAST;
        c.fill = GridBagConstraints.NONE;
        this.add(rlPanel, c);
        c.gridx++;
        c.weightx = 0;
        this.add(button, c);

        button.addActionListener(new ActionListener() {

            @Override
            public void actionPerformed(ActionEvent e) {
                button.setEnabled(false);
                final Frame frame = SwingThreadUtils.getAncestorOrSelf(Frame.class, ImportEcriturePanel.this);
                final FileDialog fd = new FileDialog(frame, "Import d'écritures", FileDialog.LOAD);
                fd.setFilenameFilter(new FilenameFilter() {
                    @Override
                    public boolean accept(File dir, String name) {
                        return name.endsWith("." + ContentTypeVersioned.SPREADSHEET.getExtension());
                    }
                });
                fd.setVisible(true);
                rlPanel.setMode(ReloadPanel.MODE_ROTATE);
                if (fd.getFile() != null) {

                    new Thread() {
                        @Override
                        public void run() {
                            final File fileToImport = new File(fd.getDirectory(), fd.getFile());
                            try {
                                final ArrayTableModel model = loadData(fileToImport);
                                try {
                                    final DBRoot rootSociete = ((ComptaPropsConfiguration) ComptaPropsConfiguration.getInstance()).getRootSociete();
                                    SQLUtils.executeAtomic(rootSociete.getDBSystemRoot().getDataSource(), new ConnectionHandlerNoSetup<Object, IOException>() {
                                        @Override
                                        public Object handle(final SQLDataSource ds) throws SQLException, IOException {
                                            try {
                                                SQLSelect sel = new SQLSelect();
                                                sel.addSelectStar(rootSociete.getTable("JOURNAL"));
                                                List<SQLRow> rowsJrnl = SQLRowListRSH.execute(sel);
                                                for (SQLRow sqlRow : rowsJrnl) {
                                                    mapJournal.put(sqlRow.getString("CODE"), sqlRow.getID());
                                                }
                                                final DateFormat format = new SimpleDateFormat("dd/MM/yyyy");
                                                final String mouvementName = "Import " + format.format(new Date());
                                                SQLBackgroundTableCache.getInstance().getCacheForTable(rootSociete.getTable("COMPTE_PCE")).setEnableReloadIfTableModified(false);
                                                // Vérification des données
                                                boolean ok = importTableModel(model, mouvementName, frame, true);
                                                if (ok) {

                                                    // Importation des données
                                                    importTableModel(model, mouvementName, frame, false);
                                                    SwingUtilities.invokeLater(new Runnable() {
                                                        @Override
                                                        public void run() {
                                                            JOptionPane.showMessageDialog(null, "Importation des écritures terminée");
                                                        }
                                                    });
                                                }
                                            } catch (Exception exn) {
                                                ExceptionHandler.handle("Erreur pendant l'importation", exn);
                                            } finally {
                                                SQLBackgroundTableCache.getInstance().getCacheForTable(rootSociete.getTable("COMPTE_PCE")).setEnableReloadIfTableModified(true);
                                            }
                                            return null;
                                        }
                                    });
                                } catch (Exception exn) {
                                    ExceptionHandler.handle(frame, "Erreur lors de l'insertion dans la base", exn);
                                }

                            } catch (Exception e) {
                                if (e.getMessage() != null && e.getMessage().toLowerCase().contains("file format")) {
                                    JOptionPane.showMessageDialog(ImportEcriturePanel.this, "Format de fichier non pris en charge");
                                } else {
                                    ExceptionHandler.handle(frame, "Erreur lors de la lecture du fichier " + fileToImport.getAbsolutePath(), e);
                                }
                            }

                            frame.dispose();
                        }
                    }.start();
                }
            }
        });
    }

    public ArrayTableModel loadData(File f) throws IOException {
        final DataImporter importer = new DataImporter();
        importer.setSkipFirstLine(false);
        return importer.createModelFrom(f);
    }

    public boolean importTableModel(ArrayTableModel m, String mvtName, final Frame owner, boolean dryRun) throws Exception {
        final DateFormat dF = new SimpleDateFormat("dd/MM/yyyy");
        final GenerationEcritures gen = new GenerationEcritures();
        int idMvt = -1;
        if (!dryRun) {
            idMvt = gen.getNewMouvement("", 1, 1, mvtName);
        }
        long soldeGlobal = 0;
        String dateOrigin = null;
        final int rowCount = m.getRowCount();
        for (int i = 0; i < rowCount; i++) {
            int column = 0;
            try {
                // @willemavjc 2020/05/29: The current format is said to be as follow.
                // <date>;<journal>;<account>;<document>;<label>;<debit>;<credit>
                // Note: Column index starts from 0.

                // Column 0: Date
                final Object firstValue = m.getValueAt(i, column);
                if (firstValue == null) {
                    break;
                }
                final Date dateValue;
                if (firstValue.getClass().isAssignableFrom(Date.class)) {
                    dateValue = (Date) firstValue;
                } else if (firstValue.toString().trim().isEmpty()) {
                    break;
                } else {
                    dateValue = dF.parse(firstValue.toString());
                }
                final String dateStringValue = dF.format(dateValue);
                if (dateOrigin == null) {
                    dateOrigin = dateStringValue;
                }
                gen.putValue("DATE", dateValue);
                column++;

                // Column 1: Journal
                final String valueJrnl = m.getValueAt(i, column).toString();
                if (!dryRun && mapJournal.get(valueJrnl) == null) {
                    SwingUtilities.invokeAndWait(new Runnable() {
                        @Override
                        public void run() {
                            final JDialog diag = new JDialog(owner);
                            diag.setModal(true);
                            diag.setContentPane(new SelectionJournalImportPanel(valueJrnl, mapJournal, null));
                            diag.setTitle("Import d'écritures");
                            diag.setLocationRelativeTo(null);
                            diag.pack();
                            diag.setVisible(true);
                        }
                    });
                }
                gen.putValue("ID_JOURNAL", this.mapJournal.get(valueJrnl));
                column++;

                // Column 2: Account
                final String trim = m.getValueAt(i, column).toString().trim();
                String numCompt = trim;
                if (trim.contains(".")) {
                    numCompt = trim.substring(0, trim.indexOf('.'));
                }
                numCompt = numCompt.trim();
                if (!dryRun) {
                    int idCpt = getOrCreateCompte(numCompt);
                    gen.putValue("ID_COMPTE_PCE", idCpt);
                }
                column++;

                // Column 3: Document
                String stringPiece = m.getValueAt(i, column).toString();
                if (stringPiece != null && stringPiece.length() > 0 && stringPiece.contains(".")) {
                    stringPiece = stringPiece.substring(0, stringPiece.indexOf('.'));
                }
                // @willemavjc 2020/05/29: Stores the document name. (Can't explain why this has been missing from the start.)
                gen.putValue("NOM_PIECE", stringPiece);
                column++;

                // Column 4: Label
                // @willemavjc 2020/05/29: Removes the concatenation of the "document" (stringPiece) to the "label".
                // gen.putValue("NOM", m.getValueAt(i, column).toString() + " " + stringPiece);
                gen.putValue("NOM", m.getValueAt(i, column).toString());
                column++;

                // Column 5: Debit
                final String stringValueD = m.getValueAt(i, column).toString();
                long montantD = GestionDevise.parseLongCurrency(stringValueD);
                gen.putValue("DEBIT", montantD);
                column++;

                // Column 6: Credit
                final String stringValueC = m.getValueAt(i, column).toString();
                long montantC = GestionDevise.parseLongCurrency(stringValueC);
                gen.putValue("CREDIT", montantC);

                // Balance
                soldeGlobal += montantD;
                soldeGlobal -= montantC;

                // Generates a new transaction identifier whenever the date has changed from the previous iteration.
                // Then stores the related id.
                if (!dateOrigin.equals(dateStringValue)) {
                    dateOrigin = dateStringValue;
                    if (!dryRun) {
                        idMvt = gen.getNewMouvement("", 1, 1, mvtName);
                    } else if (soldeGlobal != 0) {
                        final double soldeMvt = soldeGlobal / 100.0;
                        SwingUtilities.invokeLater(new Runnable() {
                            @Override
                            public void run() {
                                JOptionPane.showMessageDialog(null, "Le mouvement du " + dateStringValue + " ne respecte pas la partie double (Solde du mouvement : " + soldeMvt + ")!\nImport annulé!");
                            }
                        });
                        return false;
                    }
                }
                gen.putValue("ID_MOUVEMENT", idMvt);

                // @willemavjc 2020/05/29: Seems to be a duplicate of line 290.
                // gen.putValue("NOM", m.getValueAt(i, 4).toString() + " " + stringPiece);
            } catch (Exception e) {
                throw new IllegalStateException("Donnée invalide sur la ligne " + (i + 1) + " , colonne " + (column + 1), e);
            }
            if (!dryRun) {
                gen.ajoutEcriture();
            }
        }
        if (soldeGlobal != 0) {
            throw new IllegalArgumentException("La partie double n'est respectée (solde = " + soldeGlobal + "). Import annulé!");
        }
        return true;
    }

    private int getOrCreateCompte(String numeroCompte) {
        if (mapCompte.containsKey(numeroCompte)) {
            return mapCompte.get(numeroCompte);
        }
        int id = ComptePCESQLElement.getId(numeroCompte);
        mapCompte.put(numeroCompte, id);
        return id;
    }
}
